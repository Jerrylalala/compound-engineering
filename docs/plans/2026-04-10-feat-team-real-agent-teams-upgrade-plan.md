---
title: "feat: 将插件 [team] 升级为 Claude Code 原生 Agent Teams"
type: feat
status: active
date: 2026-04-10
---

# 将插件 [team] 升级为 Claude Code 原生 Agent Teams

## 背景与结论（Claude + Codex 交叉分析）

### 问题发现过程

用户指出插件中的 `[team]` 参数与 Claude Code 官方最新的 Agent Teams（Teammates）功能有混淆。
经过完整的代码阅读分析，结论如下。

---

## 差距分析：插件 `[team]` vs Claude Code 原生 Agent Teams

### 核心差距

| 维度 | 插件当前 `[team]`（角色模拟） | Claude Code 原生 Agent Teams（真实） |
|------|-------------------------------|--------------------------------------|
| 本质 | 同一个 agent 扮演多个角色 | 独立 context window 的真实 teammate |
| 验证者 | 主 agent 顺序执行（做完再查） | 独立 teammate，实时接收通知并验证 |
| 通信 | 读写 `.team-contract.md` 文件 | `SendMessage(name, msg)` 实时消息 |
| 并行性 | 无，所有角色顺序切换 | 真正并行，verifier 可同时准备 |
| 互相质疑 | 不能，同一 agent 无法自我挑战 | 可以，teammate 主动 SendMessage 挑战 |

### 当前插件 `[team]` 的真实本质

`ce:work [team]` 中的三个角色全部是**同一个 agent 的行为规则**：

- **合约主**：主 agent 读写 `.team-contract.md` 文件（文件 I/O，非独立进程）
- **执行者**：主 agent 遵守"只写 allowed_files"的行为约束
- **验证者**：每个 Unit 完成**之后**顺序跑测试（同一 agent，顺序切换角色）

结论：**这是角色扮演（role-playing），不是 Agent Teams。**

### Claude Code 原生 Agent Teams 的真实机制

来自 Claude Code 官方文档（2026年）：

- `TeamCreate("team-name")` → 创建命名团队
- `Agent(team=..., name="verifier", prompt=...)` → 派发真正独立的 teammate（各有独立 context window）
- `SendMessage(teammate_name, message)` → 实时 agent 间通信（不经过文件）
- 共享任务列表 `~/.claude/tasks/{team-name}/` + 文件锁防冲突
- Teammate 可以主动给其他 teammate 发消息质疑对方实现
- Hook：`TeammateIdle` / `TaskCompleted`（exit code 2 可阻断动作）

---

## 什么需要改，什么不需要改

### 不需要改（保持现状）

| 模块 | 原因 |
|------|------|
| `ce:brainstorm [team]`（探索者+挑战者） | 用户明确：这个留给 `[P]` 做，简化或去掉即可 |
| `ce:plan [team]` Phase 4.5（合约生成） | 逻辑不变，`.team-contract.md` 改为 teammates 共享上下文 |
| `ce:review [team]` Patch Gate | 纯规则引擎，不涉及 agent 通信，无需修改 |
| `.team-contract.md` 格式 | 保留，改为 teammates 启动时共同读取的协调文档 |

### 需要改（2个文件）

#### 文件1：`skills-custom/team-mode/SKILL.md`
**改动量：大（ce:work [team] 节约 80% 重写）**

当前 ce:work [team] 节描述的是角色规则声明，需改为：
```
旧：宣告角色 → 声明行为规则 → 同一 agent 顺序切换
新：TeamCreate → spawn verifier teammate → SendMessage 通信 → TeamDelete
```

ce:brainstorm / ce:plan / ce:review 节基本不变。

#### 文件2：`skills/ce-work/SKILL.md`
**改动量：中（Phase -1 全替换 + Phase 2 通信机制改）**

```
旧 Phase -1：
  Load team-mode skill → 声明合约主/执行者/验证者角色

新 Phase -1：
  TeamCreate("ce-work-{timestamp}")
  读取 .team-contract.md（来自 ce:plan [team] 生成的合约）
  Agent(team=..., name="verifier", prompt="等待 SendMessage，收到后验证，回报结果")
  [team:full] 额外 spawn risk-guard teammate
  宣告团队就绪

旧 Phase 2（每个 unit 完成后）：
  同一 agent 顺序跑 required_invariants 验证

新 Phase 2（每个 unit 完成后）：
  SendMessage("verifier", "Unit X 完成，变更文件: [...]. 请验证")
  等待 verifier 回复
  收到 PASS → 下一 unit
  收到 FAIL → 修复 → 重发 SendMessage
  全部完成 → TeamDelete
```

---

## 新的 ce:work [team] 完整流程设计

```
用户运行：/ce:work plan.md [team]

Phase -1（Team Mode 初始化）：
1. 检测 [team]/[team:full] token
2. TeamCreate("ce-work-{task-timestamp}")
3. 读取 .team-contract.md（如存在）
4. spawn verifier teammate：
   Agent(
     team="ce-work-{timestamp}",
     name="verifier",
     prompt="""
       你是验证者 teammate。
       启动后读取 .team-contract.md，了解 required_invariants。
       等待实现者通过 SendMessage 通知 unit 完成。
       收到后：
       1. 读取变更文件，运行 required_invariants 中的命令
       2. SendMessage("lead", "Unit X: PASS/FAIL. [详情]")
       持续等待下一个通知。
     """
   )
5. [team:full] 额外 spawn risk-guard teammate（拦截高风险路径）
6. 宣告：「团队已就绪：lead(主) + verifier + [risk-guard]」

Phase 2（每个 Implementation Unit）：
- lead（主 agent）执行实现（写代码）
- 完成后：SendMessage("verifier", "Unit X 已完成。变更文件: [...]")
- 等待 verifier 回复（TeammateIdle hook 或 blocking wait）
- 收到 PASS → 继续下一 unit
- 收到 FAIL → 修复 → 重发 SendMessage("verifier", ...)

Phase 4（收尾）：
- TeamDelete("ce-work-{timestamp}")
- 清理 .context/compound-engineering/ 状态文件
```

---

## 规模评估

| 文件 | 改动量 | 说明 |
|------|--------|------|
| `skills-custom/team-mode/SKILL.md` | 大 | ce:work 节 ~80% 重写，其他节基本不变 |
| `skills/ce-work/SKILL.md` | 中 | Phase -1 全替换，Phase 2 通信机制改，其余不变 |
| `plugins/compound-engineering/CLAUDE.md` | 小 | Agent Teams 集成说明更新 |
| 其他文件 | 不改 | |

**整体：中等规模，2个核心文件，不触及 ce:plan / ce:review / ce:brainstorm 的主体逻辑。**

---

## Codex 调用问题诊断与修复

### 失败原因

之前调用失败有两个根因：

1. **缺少 `-C` 参数**：Codex 默认从 `C:\` 启动，无法访问 `F:\StudyFolder\`
2. **让 Codex 自己去读文件**：触发 sandbox 权限拦截（workspace-write 沙箱限制）
   
### 正确调用姿势（来自项目脚本 scripts/codex-review-now.sh）

```bash
# 正确做法：内容嵌入 prompt，不依赖 Codex 读文件
CODEX_OUTPUT="${TEMP:-/tmp}/codex-$(date +%s).md"

printf "%s" "$PROMPT_CONTENT" | codex exec \
  -C "F:/StudyFolder/StudyDest/project/tools/compound-engineering-plugin-private" \
  --output-last-message "$CODEX_OUTPUT" \
  -

cat "$CODEX_OUTPUT"
```

关键点：
- `-C <绝对路径>` 设置工作目录
- `--output-last-message <文件>` 捕获输出
- Prompt 内容通过 stdin 传入（`-` 参数）
- **不让 Codex 自己去读文件**，所有需要分析的内容直接嵌入 prompt

### config.toml 现状

```toml
[windows]
sandbox = "elevated"

[projects.'\\?\F:\StudyFolder\StudyDest\project\tools\compound-engineering-plugin-private']
trust_level = "trusted"
```

项目已被标记为 trusted，但仍需 `-C` 确保正确的工作目录。

---

## Codex 交叉验证结果（2026-04-10）

**调用方式修复**：之前失败因为缺 `-C` 参数且让 Codex 自己读文件（触发 sandbox）。
正确姿势：内容嵌入 prompt + `-C <绝对路径>` + `--output-last-message`。

### Codex 的评估（原文）

> 1. 判断基本正确。当前 `[team]` 只有一个 agent context，`合约主/执行者/验证者` 只是同一 agent 的顺序角色切换，通信靠文件，所以是"角色模拟"，不是真实 Agent Teams。
>
> 2. 新流程方向对，但还缺几项关键约束：`verifier` 应明确只读；`SendMessage` 需要固定消息协议（unit id、变更文件、预期行为、回归范围）；要定义超时/失败重试与 `TeamDelete` 清理；全部 unit 结束后仍需一次全量集成验证。另一个问题是：如果每次都"发消息后等待"，你获得的是上下文隔离，不是并行协作。
>
> 3. `.team-contract.md` 仍然有价值，但角色应从"通信介质"降为"团队章程/共享计划"。建议改成固定结构：目标、unit 列表、文件所有权/锁策略、验证标准、消息模板、风险、退出条件。
>
> 4. Claude 漏了两点：一是应利用 `TeammateIdle / TaskCompleted` 做自动触发，而不只靠主 agent 手动发消息；二是需要崩溃恢复/重连策略，否则 team 生命周期设计不完整。

### Codex 补充的关键点（纳入计划）

1. **verifier 只读约束**：teammate prompt 中必须明确 verifier 不能写任何文件
2. **固定消息协议**：SendMessage 的格式需要规范化（unit_id / files / expected / scope）
3. **超时与崩溃恢复**：需要 team 生命周期管理（TeamDelete on failure，retry policy）
4. **全量集成验证**：所有 unit 完成后额外跑一次全局验证（不只逐 unit 验证）
5. **TeammateIdle / TaskCompleted hook**：用 hook 自动触发 verifier，比手动 SendMessage 更可靠
6. **并行 vs 顺序**："发消息后等待"是上下文隔离，不是并行——如果要真并行，需要 verifier 在后台持续运行并主动汇报

### 两方共同确认的结论

- 当前 [team] = 角色模拟，必须改
- 修改文件：team-mode/SKILL.md（大改）+ ce-work/SKILL.md（中改）
- .team-contract.md 保留，但定位从通信介质改为团队章程
- 新流程核心：TeamCreate + SendMessage + TeammateIdle hook + TeamDelete

---

---

## 外部开源项目调用 Codex/Gemini 的方式（参考研究）

### oh-my-claudecode（Yeachan-Heo）

tmux 多 worker 模式，用 `omc ask` 封装：

```bash
omc team 2:codex "review auth module"
omc team 2:gemini "redesign UI components"
omc ask codex "<prompt>"
omc ask gemini "<prompt>"
```

输出保存到 `.omc/artifacts/ask/codex-*.md`

### ccg-workflow（fengshao1227）—— **最完整的参考**

用 Go binary wrapper（`codeagent-wrapper`）管理 backend 进程。

**调 Codex 的实际命令**（来自 executor.go `buildCodexArgs`）：

```bash
codex e \
  --dangerously-bypass-approvals-and-sandbox \
  --skip-git-repo-check \
  -C /work/dir \
  --json \
  "task description"

# resume 模式：
codex e \
  --dangerously-bypass-approvals-and-sandbox \
  --skip-git-repo-check \
  --json \
  resume <session_id> "target"
```

**调 Gemini 的实际命令**：

```bash
gemini -m gemini-2.0-flash -o stream-json -y "task description"

# Windows 长 prompt 用 stdin 避免截断：
echo "task" | gemini -m gemini-2.0-flash -o stream-json -y
```

**关键 flag 说明**：

| Flag | 说明 |
|------|------|
| `--dangerously-bypass-approvals-and-sandbox` | 绕过沙箱，解决文件访问限制 |
| `--skip-git-repo-check` | 避免 git 仓库检查报错 |
| `-C /work/dir` | 设置工作目录 |
| `--json` | 输出 JSON 流（比 `--output-last-message` 更健壮） |
| `gemini -y` | 自动 yes，非交互 |
| `gemini -o stream-json` | 流式 JSON 输出 |

**Go wrapper 架构优势**：
- 独立二进制，零运行时依赖
- Go 原生并发管理多 backend 进程
- Windows `taskkill /T /F` 强制终止进程树
- JSON 流解析 + session 恢复机制

### 对我们插件的启示

当前 `commands/codex.md` 缺少关键 flags，应更新为：

```bash
# 当前（有问题）
codex exec --output-last-message "$CODEX_OUTPUT" -

# 应改为（参考 ccg-workflow）
codex exec \
  --dangerously-bypass-approvals-and-sandbox \
  --skip-git-repo-check \
  -C "$(pwd)" \
  --output-last-message "$CODEX_OUTPUT" \
  -
```

同理 `gemini` 调用应加 `-y` 和 `-o stream-json`。

---

## 待执行任务

- [x] 用正确姿势重新调用 Codex 验证分析结论（2026-04-10 完成）
- [x] 修改 `skills-custom/team-mode/SKILL.md`（ce:work [team] 节大改）（v2.46.0）
- [x] 修改 `skills/ce-work/SKILL.md`（Phase -1 + Phase 2 改）（v2.46.0）
- [x] 更新 `plugins/compound-engineering/CLAUDE.md`（Agent Teams 说明）（v2.46.0）
- [x] 更新版本号 + CHANGELOG（v2.45.27 → v2.46.0）
- [ ] 推送 PR

---

## 备注

- `ce:brainstorm [team]` 的探索者+挑战者角色：用户明确保留给 `[P]` 参数，不并入 Agent Teams 范畴
- `.team-contract.md` 保留，从"角色规则文件"改为"teammates 共享上下文文档"
- 真实 Agent Teams 需要 Claude Code 开启 Teammates 实验性功能（Settings → Agent Teams）
