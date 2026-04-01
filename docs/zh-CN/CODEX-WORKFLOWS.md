# Codex 工作流使用说明

## 最短使用路径

如果你只想知道最短怎么用，按这个顺序：

1. 在当前仓库里打开 Codex
2. 使用：

```text
/prompts:workflows-brainstorm
/prompts:workflows-plan
/prompts:workflows-review
```

3. 让 Codex 产出共享文档到：
   - `docs/brainstorms/`
   - `docs/plans/`
4. 回到 Claude，继续执行：

```text
/workflows:work docs/plans/<your-plan>.md
```

如果你后续修改了本仓库里与 `brainstorm / plan / review` 或 Codex 安装链路相关的功能，开发完成后在 Claude 里执行：

```text
/sil
```

它是这个仓库的“同步 Codex 适配层”检查步骤。

本仓库现在提供一套 repo-scoped Codex 工作流入口，位置在：

- `.codex/prompts/workflows-brainstorm.md`
- `.codex/prompts/workflows-plan.md`
- `.codex/prompts/workflows-review.md`
- `.codex/skills/compound-workflow-documents/`

它们的目标不是替换 Claude 的执行工作流，而是补一层适合 Codex 的“思考与审查层”：

- Codex 负责：`brainstorm`、`plan`、`review`
- Claude 负责：`work`

## 设计原则

共享的是**文档协议**，不是运行时实现。

- Codex 负责生成 `docs/brainstorms/` 与 `docs/plans/` 中的文档
- Claude 后续继续读取这些文档并执行 `/workflows:work`

## 本地直接使用

如果你已经在这个仓库里运行 Codex，且 Codex 会读取 repo-scoped `.codex/`，可以直接使用：

```text
/prompts:workflows-brainstorm
/prompts:workflows-plan
/prompts:workflows-review
```

### 推荐使用顺序

1. 需求不明确时：

```text
/prompts:workflows-brainstorm
```

2. 需要生成 Claude 可执行的计划时：

```text
/prompts:workflows-plan
```

3. 需要审查代码或计划时：

```text
/prompts:workflows-review
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
/workflows:work <plan_path>
```

例如：

```text
/workflows:work docs/plans/2026-04-01-feat-example-plan.md
```

## 通过安装链路写入到全局 Codex

当前仓库的 CLI 已支持把 repo-scoped Codex 文件一起带到目标 `.codex`。

### 安装到默认 `~/.codex`

```bash
bun run src/index.ts install ./plugins/compound-engineering --to codex
```

### 安装到自定义 Codex 根目录

```bash
bun run src/index.ts install ./plugins/compound-engineering --to codex --codex-home "C:\Users\你的用户名\.codex"
```

安装完成后，目标目录里应包含：

- `prompts/workflows-brainstorm.md`
- `prompts/workflows-plan.md`
- `prompts/workflows-review.md`
- `skills/compound-workflow-documents/SKILL.md`

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
