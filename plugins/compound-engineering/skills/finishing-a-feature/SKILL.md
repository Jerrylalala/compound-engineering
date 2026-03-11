---
name: finishing-a-feature
description: This skill should be used when completing a feature branch and deciding how to integrate changes (merge, PR, or push). It verifies tests, presents options, and cleans up worktrees.
disable-model-invocation: true
---

# Finishing a Feature

完成功能开发的标准化流程，确保代码质量并提供灵活的集成选项。

## 执行流程

### 1. 验证测试通过

在提供任何选项前，必须验证所有测试通过：

```bash
# 运行完整测试套件
npm test  # 或项目对应的测试命令

# 检查退出码
echo $?  # 必须为 0
```

**验证标准**：
- 所有测试通过（0 failures）
- 构建成功（exit 0）
- 无 lint 错误

**铁律：测试失败 = 流程终止。** 不提供"继续"或"跳过"选项。修复所有测试后重新进入此流程。

### 2. 确认基础分支

询问用户目标基础分支（通常是 `main` 或 `develop`）：

> "目标基础分支是什么？（默认：main）"

### 3. 呈现 4 个选项

向用户展示以下选项：

| 选项 | 操作 | 适用场景 |
|------|------|----------|
| **A** | 直接合并到基础分支 | 小改动、hotfix、个人项目 |
| **B** | 创建 PR（保留分支） | 需要 Code Review、团队协作 |
| **C** | 创建 PR + 删除本地分支 | 完成后不再需要本地分支 |
| **D** | 仅推送分支（不合并/PR） | 需要备份或稍后处理 |

### 4. 执行用户选择

#### 选项 A：直接合并

```bash
git checkout <base-branch>
git pull origin <base-branch>
git merge --no-ff <feature-branch>
git push origin <base-branch>
git branch -d <feature-branch>
```

#### 选项 B：创建 PR（保留分支）

```bash
git push origin <feature-branch>
gh pr create --base <base-branch> --head <feature-branch> --title "..." --body "..."
```

#### 选项 C：创建 PR + 删除本地分支

```bash
git push origin <feature-branch>
gh pr create --base <base-branch> --head <feature-branch> --title "..." --body "..."
git checkout <base-branch>
git branch -D <feature-branch>
```

#### 选项 D：仅推送分支

```bash
git push origin <feature-branch>
```

### 5. 清理 Worktree（如适用）

如果在 worktree 中工作，询问是否清理：

```bash
# 退出 worktree
cd <original-directory>

# 删除 worktree
git worktree remove <worktree-path>
```

## 快速参考

| 命令 | 说明 |
|------|------|
| `npm test` | 运行测试 |
| `git merge --no-ff` | 保留分支历史的合并 |
| `gh pr create` | 创建 Pull Request |
| `git branch -d/-D` | 删除本地分支（-D 强制） |
| `git worktree remove` | 删除 worktree |

## 关联技能

- [git-worktree](../git-worktree/SKILL.md) - Worktree 管理
- [test-driven-development](../test-driven-development/SKILL.md) - TDD 流程
- [workflows:work](../../commands/workflows/work.md) - 工作流执行
