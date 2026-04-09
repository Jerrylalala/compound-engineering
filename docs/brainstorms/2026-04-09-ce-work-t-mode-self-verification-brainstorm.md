---
date: 2026-04-09
topic: ce-work-t-mode-self-verification
---

# ce:work [T] 模式：多层自验证闭环

## What We're Building

为 `ce:work` 增加可选的 `[T]` 参数，让 AI 在完成代码实现后，自动执行多层验证，从用户视角确认功能正确——而不是等到 `ce:review` 阶段才发现问题。

**核心问题**：当前 ce:work 的"完成"= 代码写完。应该改为"完成"= 通过验证。

## Why This Approach

### 背景分析

参考了三个外部项目的真实文件：

**SamuelQZQ/auto-coding-agent-demo**（775⭐）：
- `task.json` passes:false→true 状态机
- CLAUDE.md 写入强制验证规则
- 多模态验证（Playwright 浏览器 + API + DB）
- 文件系统状态比内存状态可靠（跨 session 存活）

**Superpowers plugin**（真实文件已读）：
- TDD 铁律：先写失败测试，再实现（`test-driven-development/SKILL.md`）
- "不信任实现者报告"：独立 reviewer 读代码核查（`spec-reviewer-prompt.md`）
- verification-before-completion：无新鲜证据不得声称完成

**SWE-agent / OpenHands / aider**（业界成熟方案）：
- 完成 = 可重复命令通过，exit code + stdout/stderr 自动回环修复
- 外部裁判不信任 agent 自报（SWE-bench/agbenchmark 模式）

**Vercel agent-browser 实验数据**：
- 17 工具 → 80% 成功，274 秒
- 2 工具 → 100% 成功，77 秒
- 结论：工具越精简，成功率越高

### 当前仓库已有的能力

```
✅ agent-browser skill：plugins/compound-engineering/skills/agent-browser/（完整）
✅ Playwright MCP：mcp__playwright__* 工具已在环境
✅ ce:work [team][team:full][R] 参数体系
✅ spec-compliance-review 已实现
✅ verification-before-completion 理念已在 CLAUDE.md
```

**这是组合现有能力，不是从零建造。**

## Key Decisions

### 决策 1：[T] 是可选参数，不强制

- `ce:work` = 快速模式，写完交付（适合小改动、快速迭代）
- `ce:work [T]` = 保障模式，四层自验证（适合新功能、关键路径）
- 理由：强制对无 UI 任务（纯文档、配置）没有意义且浪费 token

### 决策 2：四层验证架构（Codex 确认最优）

```
Layer 0：CLI 静态检查（Bash exit code，0 token）
  → 项目 CLAUDE.md 定义的命令：npm build / pytest / cargo test
  → exit code 非 0 = 失败，停止

Layer 1：API/DB 验证（curl + DB CLI）
  → 仅当任务涉及后端/数据库时触发
  → 调用接口 + 查数据库状态

Layer 2：Browser UI 验证（智能选层）
  → 默认：agent-browser（已有 skill，token 低 30-50 倍）
      snapshot → 操作 → diff → console 无错误
  → 深度验证时升级：Playwright MCP
      browser_network_requests / browser_console_messages / browser_evaluate
  → 触发条件：任务涉及前端/UI/交互

Layer 3：验收确认（独立 reviewer）
  → 对照 ce:plan 里写好的验收场景
  → "不信任实现者报告"（Superpowers 原则）
  → 读证据文件独立核查
```

### 决策 3：[T] = agent-browser（默认），[T][PW] = Playwright MCP（显式升级）

工具选择通过**显式参数**而非关键词自动判断：

| 参数组合 | Layer 2 工具 | 原因 |
|----------|-------------|------|
| `[T]` | agent-browser（内置） | token 低 30-50 倍，足够用于菜单/按钮/截图 |
| `[T][PW]` | Playwright MCP | 需要网络拦截/JS执行/拖拽/文件上传时，用户显式开启 |

**为什么不自动判断**：
- 关键词匹配容易误判（任务描述含「UI」不代表需要 Playwright MCP）
- 自动升级会意外消耗大量 token（Playwright MCP 每页 15000+ token）
- 用户最清楚这个任务需要什么级别的浏览器验证
- 更透明：用户看到 `[PW]` 就知道在用高精度工具

**参数说明**：
- `[PW]` = Playwright Mode，仅在 `[T]` 同时存在时生效
- Layer 2 是否执行仍然基于任务类型判断（非前端任务 skip Layer 2）
- `[PW]` 只影响 Layer 2 的工具选择，不改变其他层

### 决策 4：passes 状态机（SamuelQZQ 模式）

- 文件系统记录状态（不用内存，跨 session 存活）
- 四层全通过 → passes:true → 标记任务完成
- 任意层失败 → 自动修复 → 重跑（≤2 轮）
- 2 轮仍失败 → BLOCKED，停下来问用户

**状态文件**：`.ce-work-verification.json`（存于项目根目录，gitignore）

```json
{
  "task_id": "T001",
  "description": "实现设置面板",
  "verification_rounds": 1,
  "layers": {
    "layer0": "pass",
    "layer1": "skip",
    "layer2": "pass",
    "layer3": "pending"
  },
  "passes": false
}
```

文件在任务开始时创建，全通过后 `passes:true`，任务完成后清理（或保留供审计）。

### 决策 5：计划阶段写验收场景

- ce:plan 加一个「验收场景」章节
- 每个功能附带用户视角的成功标准
- ce:work [T] 执行时读取这些场景作为 Layer 3 的判断依据

**验收场景格式（标准模板）**：

```markdown
## 验收场景（[T] 模式使用）

| # | 场景 | 操作步骤 | 期望结果 | 层级 |
|---|------|----------|----------|------|
| 1 | 菜单切换显示正确 | 点击「设置」标签 | 显示设置面板，无控制台报错 | Layer 2 |
| 2 | API 返回正确数据 | POST /api/tasks | 返回 200，body 含 id 字段 | Layer 1 |
| 3 | 构建无报错 | npm run build | exit code 0 | Layer 0 |
```

有 [T] 参数时，ce:plan 必须包含此章节，否则 ce:work [T] 的 Layer 3 将警告"无验收场景"。

### 决策 6：这个插件本身（Markdown skill 文件）不适用 [T] 模式

- 这个插件的产出是提示词文件，没有可运行的产物
- 对插件本身，只能用 Layer 0（脚本结构验证）+ Layer 3（AI 读回验证）
- 浏览器验证不适用（无 UI）

## 实现范围（最小改动）

```
1. ce:work SKILL.md：
   - Phase -1 扩展：检测 [T] 参数
   - 新增 Phase 3.5：四层验证执行
   - argument-hint 更新

2. ce:plan SKILL.md（或 plan 模板）：
   - 加「验收场景」章节格式

3. 无需新建文件：
   - agent-browser skill 已存在
   - Playwright MCP 工具已可用
```

## Token 成本

| 模式 | 每任务 Token | 可靠性 |
|------|------------|--------|
| 当前（无验证） | 基准 | 低（bug 流入 review） |
| ce:work [T] | +20-40% | 高 |
| Superpowers 全套 | +200-300% | 极高 |

### 决策 7：Layer 触发判断规则

ce:work [T] 根据任务描述和文件变更自动判断需要激活哪些层：

| 触发信号 | 激活层 | 判断依据 |
|----------|--------|----------|
| 任务描述含「前端/UI/组件/页面/样式/交互」 | Layer 2 | 关键词匹配 |
| 变更文件含 `.tsx/.vue/.html/.css` | Layer 2 | 文件扩展名 |
| 任务描述含「API/接口/数据库/路由/endpoint」 | Layer 1 | 关键词匹配 |
| 变更文件含「routes/controllers/models/migrations」 | Layer 1 | 路径模式 |
| 任务描述含「Markdown/文档/提示词/SKILL」 | 跳过 Layer 1/2，仅 Layer 0 + Layer 3 | 关键词匹配 |
| 项目 CLAUDE.md 中有构建命令 | Layer 0 | 始终激活 |

不确定时 → 默认激活 Layer 0 + Layer 3，Layer 1/2 提示用户确认。

### 决策 8：[T] + [team] 组合行为

当 `ce:work [T][team]` 同时使用时：

- Layer 0-2 由执行者（agent）自动运行
- Layer 3 的独立 reviewer **就是** team-mode 的验证者 Hook（复用，不重复）
- BLOCKED 状态 → 触发 team-mode 的人工检查点（而非单独问用户）
- 设计倾向：[T] 的 Layer 3 和 [team] 的验证者 Hook 合并为同一步骤

## Open Questions

- ~~ce:plan 的验收场景是否强制~~（已决策：有 [T] 时必须有验收场景，已在决策 5 中定义）
- `.ce-work-verification.json` 文件是否保留供审计（建议：默认保留 3 天后清理，或加 `--clean` 参数）
- 项目没有启动 dev server 时的处理策略（建议：ce:work 先尝试启动，失败则跳过 Layer 2 并警告）
- Layer 2 验证时 agent-browser 启动超时（建议：30 秒超时，失败降级为截图对比）

## Next Steps

→ `/ce:plan` 规划具体实现步骤
