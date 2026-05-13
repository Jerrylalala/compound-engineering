# Codex 工作流使用说明

## 最短使用路径

如果你只想知道最短怎么用，按这个顺序：

1. 在当前仓库里打开 Codex
2. 优先使用 skills 入口：

```text
$workflows-brainstorm
$workflows-plan
$workflows-review
```

3. 让 Codex 产出共享文档到：
   - `docs/brainstorms/`
   - `docs/plans/`
4. 回到 Claude，继续执行：

```text
/ce:work docs/plans/<your-plan>.md
```

如果你后续修改了本仓库里与 `brainstorm / plan / review` 或 Codex 最小技能同步相关的功能，开发完成后在 Claude 里执行：

```text
/sil
```

它是这个仓库的“同步 Codex 适配层”检查步骤。

本仓库现在提供一套 repo-scoped Codex 工作流技能，位置在：

- `.codex/skills/workflows-brainstorm/`
- `.codex/skills/workflows-plan/`
- `.codex/skills/workflows-review/`

它们的目标不是替换 Claude 的执行工作流，而是补一层适合 Codex 的“思考与审查层”：

- Codex 负责：`brainstorm`、`plan`、`review`
- Claude 负责：`work`

## 设计原则

共享的是**文档协议**，不是运行时实现。

- Codex 负责生成 `docs/brainstorms/` 与 `docs/plans/` 中的文档
- Claude 后续继续读取这些文档并执行 `/ce:work`

## 本地直接使用

如果你已经在这个仓库里运行 Codex，推荐直接通过 skills 调用：

```text
$workflows-brainstorm
$workflows-plan
$workflows-review
```

更稳的自然语言写法：

```text
Use $workflows-plan to create a plan for ...
Use $workflows-brainstorm to explore ...
Use $workflows-review to review ...
```

## 为什么不用 `/prompts:` 作为主入口

因为 Codex 官方已经把 custom prompts 标记为 deprecated，而且不同 CLI / UI 版本里不一定还会把它们暴露成可执行 slash commands。

所以本仓库现在的原则是：

- **skills 是主入口**
- 不再把 `.codex/prompts/` 当成主交互入口

### 推荐使用顺序

1. 需求不明确时：

```text
$workflows-brainstorm
```

常用参数：

- `[P]`：3 个核心视角，至少两轮讨论后再收敛
- `[P+]`：8-12 个视角深度发散，适合模糊、高风险或架构性问题
- `[R]`：强制检索 `docs/solutions/` 历史经验；Standard/Deep 场景即使不传也会自动检索

Codex 版 brainstorm 不再提供外部 AI 咨询参数；它只负责本地上下文、历史经验、方案比较和文档化。

2. 需要生成 Claude 可执行的计划时：

```text
$workflows-plan
```

3. 需要审查代码或计划时：

```text
$workflows-review
```

## 给维护者的规则

后续在 Claude Code 中开发本项目时，如果改动影响了以下任一项，必须同步 Codex 层：

- `plugins/compound-engineering/commands/workflows/brainstorm.md`
- `plugins/compound-engineering/commands/workflows/plan.md`
- `plugins/compound-engineering/commands/workflows/review.md`
- 共享文档协议
- `install --to codex` 的发现或复制逻辑

推荐做法：

```text
/sil
```

维护权威入口：

- 根目录 `CLAUDE.md` 中的 “Codex 集成同步（铁律）”
- `.claude/commands/sil.md`

## 与 Claude 的衔接

Codex 产物写入：

- `docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md`
- `docs/plans/YYYY-MM-DD-<type>-<descriptive-name>-plan.md`

然后你可以回到 Claude，继续使用：

```text
/ce:work <plan_path>
```

例如：

```text
/ce:work docs/plans/2026-04-01-feat-example-plan.md
```

## 通过安装链路写入到全局 Codex

当前仓库已经提供最小同步脚本，只同步这 3 个 Codex workflow skill。

### 推荐：同步到默认 `~/.codex`

```powershell
powershell -ExecutionPolicy Bypass -File scripts/sync-codex-workflows.ps1
```

### 同步到自定义 Codex 根目录

```powershell
powershell -ExecutionPolicy Bypass -File scripts/sync-codex-workflows.ps1 -CodexHome "C:\Users\你的用户名\.codex"
```

安装完成后，目标目录里应包含并更新这三个 workflow 入口：

- `skills/workflows-brainstorm/SKILL.md`
- `skills/workflows-plan/SKILL.md`
- `skills/workflows-review/SKILL.md`

同步脚本会移除已知的旧 workflow 入口（如 `ce-*` 工作流副本和旧 prompt），但不会清理用户自己安装的其它全局 Codex skills。

## 不推荐的做法

不要把下面这条命令当成日常同步 Codex 的方法：

```bash
bun run src/index.ts install ./plugins/compound-engineering --to codex
```

原因：

- 它会安装整个转换后的插件
- 会把额外的 `ce-*`、其他 `workflows-*` 也带到 `~/.codex`
- 不符合“Codex workflow 只维护这 3 个主入口”的目标

## 给 AI 的明确规则

如果后续是 Claude Code、Codex 或其他 AI 代理帮你做同步，不要让它自己猜同步方式。

本仓库的默认规则应理解为：

1. 用户说“同步到 Codex”“更新 Codex 里的版本”“让 Codex 用最新版本”
   - 默认执行：
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts/sync-codex-workflows.ps1
   ```
2. 不允许改用任何 `install --to codex`
3. 如果 AI 想执行完整安装，应视为违反本仓库规则，除非用户明确要求“重新安装整插件到 Codex”

项目内可直接使用：

```text
/sync-codex-workflows
```

或者：

```text
/sil
```

其中：

- `/sync-codex-workflows` = 直接执行最小同步
- `/sil` = 同步检查 + 最小同步

## 兼容性要求

Codex 写出的 plan 要满足 Claude 兼容协议：

- 路径在 `docs/plans/`
- 有 `risk_score`、`risk_level`、`risk_note`
- 包含 `## Overview`
- 包含 `**Goal**`、`**Tech Stack**`
- 包含真实 `- [ ]` checkbox 任务

完整规则见：

- `docs/specs/codex-workflow-compatibility.md`

## 注意事项

1. 不要把 Codex 专属运行时术语写进共享 plan 正文
2. 不要修改 Claude 主 workflow 来“迁就” Codex
3. Codex 侧优先做分析、规划、审查；执行仍交给 Claude
