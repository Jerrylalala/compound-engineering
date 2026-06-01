# 自定义技能（skills-custom）

本目录用于存放本 fork 的 overlay 技能。它们是公开仓库里可见的增强层，但不属于 `compound-engineering` 稳定默认技能清单，也不会随 Claude manifest 自动触发。

每个技能一个目录，目录内至少包含 `SKILL.md`（可附带 `assets/`、`references/`、`scripts/` 等）。

## 使用边界

- 面向维护者或高级用户：需要明确知道何时手动加载对应 skill。
- 不作为 README / marketplace 里的默认能力承诺，除非已经补齐安装说明、验证路径和兼容性说明。
- 若某个 overlay 技能要升级为稳定公共能力，应移动到 `skills/`，同步公开文档，并运行 release metadata 验证。

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
