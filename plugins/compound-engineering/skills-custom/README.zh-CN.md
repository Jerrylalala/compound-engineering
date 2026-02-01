# 自定义技能（skills-custom）

本目录用于存放自定义技能。每个技能一个目录，目录内至少包含 `SKILL.md`（可附带 `assets/`、`references/`、`scripts/` 等）。

## 命名规范

- 全小写
- 使用短横线分隔（kebab-case）
- 简短、语义清晰

## 目录结构示例

```
skills-custom/
  my-custom-skill/
    SKILL.md           # 必需：技能定义
    assets/            # 可选：静态资源
    references/        # 可选：参考文档
    scripts/           # 可选：脚本文件
```

## 创建新技能

直接在本目录创建子目录，并添加 `SKILL.md` 文件即可。

```bash
mkdir skills-custom/my-skill
touch skills-custom/my-skill/SKILL.md
```

## SKILL.md 模板

```markdown
---
name: my-skill
description: This skill should be used when...
---

# 技能名称

## 用途
- 描述技能的作用

## 使用方式
- 触发条件
- 输入/输出

## 示例
...
```
