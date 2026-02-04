# Compounding Engineering Plugin Development

## Versioning Requirements

> **详细规范**：见 [版本管理规范](../../docs/development/VERSIONING.md)

**快速检查**：
```powershell
powershell -ExecutionPolicy Bypass -File ../../scripts/check-versions.ps1
```

**快速更新**：
```powershell
powershell -ExecutionPolicy Bypass -File ../../scripts/bump-version.ps1 -BumpType patch
```

### Directory Structure

```
agents/
├── review/     # Code review agents
├── research/   # Research and analysis agents
├── design/     # Design and UI agents
├── workflow/   # Workflow automation agents
└── docs/       # Documentation agents

commands/
├── workflows/  # Core workflow commands (workflows:plan, workflows:review, etc.)
└── *.md        # Utility commands

skills/
└── *.md        # All skills at root level
```

## Command Naming Convention

**Workflow commands** use `workflows:` prefix to avoid collisions with built-in commands.

**Why `workflows:`?** Claude Code has built-in `/plan` and `/review` commands. Using `name: workflows:plan` in frontmatter creates a unique `/workflows:plan` command with no collision.

### Workflow 命令列表

| 序号    | 命令                    | 说明           |
| ------- | ----------------------- | -------------- |
| Step 0: | `/workflows:load`       | 加载项目上下文 |
| Step 1: | `/workflows:brainstorm` | 探索需求和方案（支持 [P][C][G]） |
| Step 2: | `/workflows:plan`       | 创建实施计划   |
| Step 3: | `/workflows:work`       | 执行工作计划   |
| Step 4: | `/workflows:review`     | 代码审查       |
| Step 5: | `/workflows:compound`   | 记录解决方案   |
| Step 6: | `/workflows:save`       | 保存项目上下文 |

### 序号格式规范

> ⚠️ 避免使用 Unicode 特殊字符（①②③），在某些终端显示异常。

```yaml
# 正确
description: "Step X: 描述内容"

# 错误
description: ① 描述内容
```

新增 workflow 命令时，按顺序分配 Step 编号。

## Command Frontmatter 参考

### `claude-code-only: true`

标记命令仅在 Claude Code 中可用。转换到 Codex/Gemini 格式时，标记为 `claude-code-only` 的命令会被自动跳过。

适用于依赖 Claude Code 特有能力（如 Bash 工具、对话上下文分析）的命令，例如 `/gemini`、`/codex`。

```yaml
---
name: gemini
description: 向 Gemini 寻求更优方案
claude-code-only: true
---
```

## Skill Compliance Checklist

When adding or modifying skills, verify compliance with skill-creator spec:

### YAML Frontmatter (Required)

- [ ] `name:` present and matches directory name (lowercase-with-hyphens)
- [ ] `description:` present and uses **third person** ("This skill should be used when..." NOT "Use this skill when...")

### Reference Links (Required if references/ exists)

- [ ] All files in `references/` are linked as `[filename.md](./references/filename.md)`
- [ ] All files in `assets/` are linked as `[filename](./assets/filename)`
- [ ] All files in `scripts/` are linked as `[filename](./scripts/filename)`
- [ ] No bare backtick references like `` `references/file.md` `` - use proper markdown links

### Writing Style

- [ ] Use imperative/infinitive form (verb-first instructions)
- [ ] Avoid second person ("you should") - use objective language ("To accomplish X, do Y")

### Quick Validation Command

```bash
# Check for unlinked references in a skill
grep -E '`(references|assets|scripts)/[^`]+`' skills/*/SKILL.md
# Should return nothing if all refs are properly linked

# Check description format
grep -E '^description:' skills/*/SKILL.md | grep -v 'This skill'
# Should return nothing if all use third person
```

## Documentation

- [版本管理规范](../../docs/development/VERSIONING.md)
- [脚本使用说明](../../docs/zh-CN/SCRIPTS.md)
- [核心概念](../../docs/zh-CN/CONCEPTS.md)
