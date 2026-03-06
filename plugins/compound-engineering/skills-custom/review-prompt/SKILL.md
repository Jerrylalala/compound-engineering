---
name: review-prompt
description: This skill should be used when reviewing or improving AI prompt files (.md command/skill definitions). It evaluates clarity, completeness, and effectiveness of prompt instructions.
---

# 提示词审查技能

## 触发条件

当需要审查或改进 AI 提示词文件（commands/*.md、skills/*/SKILL.md）时使用。

## 审查维度

1. **清晰度**：指令是否明确无歧义？AI 能否只按一种方式理解？
2. **完整性**：是否覆盖所有场景（成功、失败、边缘情况）？
3. **一致性**：术语、格式、语气是否前后一致？
4. **可测试性**：是否有可验证的输出标准？
5. **简洁性**：是否有冗余指令？能否精简而不损失信息？

## 执行流程

1. 读取目标提示词文件
2. 按 5 个维度逐一评分（1-5 分）
3. 对低分项生成具体改进建议（含改写示例）
4. 输出审查报告
