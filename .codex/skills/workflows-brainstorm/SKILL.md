---
name: workflows-brainstorm
description: 探索需求和方案，并写出可继续规划的 brainstorm 文档
---

# workflows-brainstorm

用于在实现前澄清做什么，而不是直接进入编码。

## 目标

通过协作对话、轻量仓库研究和方案比较，产出一份可继续规划的 brainstorm 文档：

`docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md`

## 输入

- 功能想法
- 问题描述
- 改进方向
- 可选参数：`[P]` 表示启用多视角讨论

如果用户没有给出清晰主题，先追问，不要直接写文档。

## 执行步骤

1. 判断需求是否已经足够清晰。
2. 如果不清晰，逐个问题追问：
   - 目标是什么
   - 谁会受影响
   - 成功标准是什么
   - 有什么约束
3. 轻量查看仓库中是否已有相近实现或相关文档。
4. 给出 2-3 个可选方案，并说明推荐项。
5. 如果用户接受某个方向，写入 brainstorm 文档。

## 文档要求

文档至少包含以下章节：

- `## What We're Building`
- `## Why This Approach`
- `## Approaches Considered`
- `## Key Decisions`
- `## Open Questions`
- `## Next Step`

文档要简洁，但必须保留：

- 选择了什么
- 为什么这样选
- 放弃了什么
- 还有什么待定问题

## 约束

- 不要开始编码
- 不要写实现细节
- 重点是 WHAT，不是 HOW

## 完成后的引导

完成后告诉用户：

- brainstorm 文件路径
- 关键决策摘要
- 下一步建议使用 `$workflows-plan`
