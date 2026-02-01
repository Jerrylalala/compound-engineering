# Compounding Engineering Plugin Development

## Versioning Requirements

**IMPORTANT**: Every change to this plugin MUST include updates to all four files:

1. **`.claude-plugin/plugin.json`** - Bump version using semver
2. **`../../.claude-plugin/marketplace.json`** - Sync version (Marketplace reads this!)
3. **`CHANGELOG.md`** - Document changes using Keep a Changelog format
4. **`README.md`** - Verify/update component counts and tables

> ⚠️ **Version mismatch = Marketplace update fails!** The version in `marketplace.json` must match `plugin.json`.

### Version Bumping Rules

- **MAJOR** (1.0.0 → 2.0.0): Breaking changes, major reorganization
- **MINOR** (1.0.0 → 1.1.0): New agents, commands, or skills
- **PATCH** (1.0.0 → 1.0.1): Bug fixes, doc updates, minor improvements

### Pre-Commit Checklist

Before committing ANY changes:

- [ ] Version bumped in `.claude-plugin/plugin.json`
- [ ] Version synced in `../../.claude-plugin/marketplace.json` (MUST match!)
- [ ] CHANGELOG.md updated with changes
- [ ] README.md component counts verified
- [ ] README.md tables accurate (agents, commands, skills)
- [ ] plugin.json description matches current counts

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

**Workflow commands** use `workflows:` prefix to avoid collisions with built-in commands:

| 序号 | 命令 | 说明 |
|------|------|------|
| Step 0: | `/workflows:load` | 加载项目上下文 |
| Step 1: | `/workflows:brainstorm` | 探索需求和方案 |
| Step 2: | `/workflows:plan` | 创建实施计划 |
| Step 3: | `/workflows:work` | 执行工作计划 |
| Step 4: | `/workflows:review` | 代码审查 |
| Step 5: | `/workflows:compound` | 记录解决方案 |
| Step 6: | `/workflows:save` | 保存项目上下文 |

**Why `workflows:`?** Claude Code has built-in `/plan` and `/review` commands. Using `name: workflows:plan` in frontmatter creates a unique `/workflows:plan` command with no collision.

### Workflow 命令序号规范

> ⚠️ **避免使用 Unicode 特殊字符！** 圆圈数字（①②③）在某些终端显示异常。

**正确格式：**
```yaml
description: "Step X: 描述内容"
```

**错误格式：**
```yaml
description: ① 描述内容    # 终端兼容性差
description: 1. 描述内容   # 格式不统一
```

新增 workflow 命令时，按顺序分配 Step 编号。

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

See `docs/solutions/plugin-versioning-requirements.md` for detailed versioning workflow.
