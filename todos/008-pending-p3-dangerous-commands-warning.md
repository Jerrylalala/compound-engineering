---
id: 008-pending-p3-dangerous-commands-warning
status: pending
priority: P3
created: 2026-03-11
tags: [documentation, safety, user-protection]
---

# 危险命令缺少警告

## 问题描述

在 `docs/plans/2026-03-11-review-changes-summary.md` 中，提到了以下危险命令但未添加警告标识：

- `git reset --hard`（会丢失未提交的更改）
- `rm -rf`（会永久删除文件）

这些命令如果误操作会造成数据丢失，应该添加明显的警告标识。

## 位置

- 文件：`docs/plans/2026-03-11-review-changes-summary.md`
- 相关命令：`git reset --hard`, `rm -rf`

## 影响

- **严重程度**：P3（低优先级，但关乎用户安全）
- **影响范围**：用户误操作风险
- **潜在后果**：数据丢失

## 建议方案

为危险命令添加警告标识，例如：

```markdown
⚠️ **警告**：`git reset --hard` 会永久丢失所有未提交的更改，请确保已备份重要内容。

⚠️ **警告**：`rm -rf` 会永久删除文件且无法恢复，请仔细确认路径。
```

或使用更醒目的格式：

```markdown
> ⚠️ **危险操作**：此命令会永久删除数据，无法撤销。
```

## 实施步骤

1. 搜索项目中所有包含危险命令的文档
2. 为每个危险命令添加警告标识
3. 建立危险命令清单（可选）
4. 在文档规范中添加"危险命令标注规则"

## 危险命令清单（参考）

| 命令 | 风险 | 建议替代 |
|------|------|----------|
| `git reset --hard` | 丢失未提交更改 | `git stash` |
| `git push --force` | 覆盖远程历史 | `git push --force-with-lease` |
| `rm -rf` | 永久删除文件 | 先 `ls` 确认，或使用回收站 |
| `git clean -fd` | 删除未跟踪文件 | 先 `git clean -n` 预览 |

## 参考

- UI 设计理念：「不让用户思考，也不让用户受伤」
- 执行戒律：「不让用户因误操作而受损」
