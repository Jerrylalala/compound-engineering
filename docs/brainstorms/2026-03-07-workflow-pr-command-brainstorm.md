# Brainstorm: /workflows:pr 命令 - PR 创建与合并

**日期：** 2026-03-07
**状态：** 已完成
**参与者：** 用户 + Claude

## What We're Building

一个新的独立 workflow 命令 `/workflows:pr`，用于在完成功能开发或代码审查后：

1. 自动检测当前分支和主分支（main/master）
2. 从 git log 和 diff 自动生成 PR 标题和描述
3. 使用 `gh pr create` 创建 PR
4. 创建后立即询问用户是否合并到主分支
5. 如果合并，执行 `gh pr merge --squash --delete-branch`

**目标用户场景**：完成一个大功能后，方便本地查看更改记录，通过 PR 形式归档变更。

## Why This Approach

### 选择方案 B（独立命令）的理由

| 评估维度 | 方案 A（扩展现有命令） | 方案 B（独立命令） | 方案 C（混合方案） |
|----------|----------------------|-------------------|-------------------|
| 改动范围 | 修改 2 个文件 | 新建 1 个 + 修改 2 个 | 新建 1 个 + 修改 2 个 |
| 代码复用 | 重复代码 | 逻辑集中 | 逻辑集中 |
| 灵活性 | 仅在 work/review 后 | 任何时候可调用 | 任何时候可调用 |
| 复杂度 | 低 | 低 | 中（需 Skill 调用） |
| 符合架构 | 一般 | 好（职责单一） | 好 |

**最终选择：方案 B**
- 符合项目现有的命令架构（每个命令职责单一）
- 可独立调用，不局限于 work/review 之后
- 在 work 和 review 的 Handoff 中添加选项即可串联

## Key Decisions

### 1. 触发方式
**决定：** 两者都支持
- `/workflows:work` 完成后的 Handoff 中添加选项
- `/workflows:review` 完成后的 Handoff 中添加选项
- 用户也可随时手动运行 `/workflows:pr`

### 2. 目标分支
**决定：** 自动检测主分支
- 使用 `git symbolic-ref refs/remotes/origin/HEAD` 检测
- Fallback: 检查 `origin/main` 或 `origin/master`

### 3. 合并行为
**决定：** 创建后立即询问是否合并
- 创建 PR 后使用 AskUserQuestion 询问用户
- 如果同意合并，执行 `gh pr merge --squash --delete-branch`
- 合并策略：`--squash`（将所有 commit 压缩为一个，保持主分支整洁）

### 4. PR 标题和描述
**决定：** 自动生成
- 标题：从 git log 中提取（分支名 + 首个 commit 摘要）
- 描述：自动生成 Summary（基于 diff 和 commit 历史）
- 包含 Compound Engineered 徽章

### 5. 命令定位
**决定：** 独立工具命令
- `description: "独立工具: 创建 PR 并询问是否合并到主分支"`
- 不是流程步骤，不分配 Step 编号

## Implementation Notes

### 命令文件位置
`plugins/compound-engineering/commands/workflows/pr.md`

### 需要修改的文件
1. `commands/workflows/pr.md` - 新建
2. `commands/workflows/work.md` - Handoff 添加 PR 选项
3. `commands/workflows/review.md` - Handoff 添加 PR 选项
4. `plugins/compound-engineering/CLAUDE.md` - 更新命令列表
5. `CLAUDE.md` - 更新命令数量
6. `CHANGELOG.md` - 记录新功能

### PR 创建前的安全检查
- 检查是否在主分支上（禁止从 main/master 创建 PR）
- 检查是否有未提交的更改（提示先 commit）
- 检查远程分支是否已推送
- 检查是否已有同名 PR

### Handoff 协议合规
- 作为独立工具命令，需满足工具档规则（规则 2/4/5）
- 使用 AskUserQuestion 呈现合并选项
- 包含"跳过"选项
- 包含 `Based on selection:` 行为约束

## Open Questions

无。需求已明确。

## 外部 AI 咨询结果

### Codex 咨询

Codex CLI 可用但咨询失败（ChatGPT 账户不支持 `o4-mini` 模型）。

```
ERROR: {"detail":"The 'o4-mini' model is not supported when using Codex with a ChatGPT account."}
```

**影响**：无。Claude 的分析和用户确认的决策已足够完整。

## Next Steps

运行 `/workflows:plan` 将此 brainstorm 转化为实施计划。
