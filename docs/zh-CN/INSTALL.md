# Claude Code 插件安装指南

本文档记录如何将本地 compound-engineering 插件安装到 Claude Code。

## 快速开始

**本地开发使用 `--plugin-dir` 标志启动 Claude Code：**

```bash
claude --plugin-dir "F:\StudyFolder\StudyDest\project\compound-engineering-plugin-private\plugins\compound-engineering"
```

修改插件后，重启 Claude Code 即可生效。

---

## Claude Code 扩展系统概览

Claude Code 有三种扩展方式，**不要混淆**：

| 类型 | 存放位置 | 调用方式 | 示例 |
|------|---------|---------|------|
| **独立技能** | `~/.claude/skills/` | 直接名称 | `glue-coding` |
| **插件技能** | 插件内 `skills/` | `插件名:技能名` | `superpowers:brainstorming` |
| **插件命令** | 插件内 `commands/` | 斜杠命令 | `/workflows:plan` |
| **插件 Agent** | 插件内 `agents/` | 系统自动调用 | `superpowers:code-reviewer` |

### 关键区别

1. **独立技能**（`~/.claude/skills/`）
   - 手动添加的技能目录
   - 直接使用名称调用
   - 不需要安装插件

2. **插件**（通过安装或 `--plugin-dir` 加载）
   - 包含 skills、commands、agents
   - 技能和命令带有插件前缀
   - 需要正式安装或通过 `--plugin-dir` 加载

---

## 本地开发（推荐）

### 使用 `--plugin-dir` 标志

这是**官方推荐的本地开发方式**，直接加载插件而无需安装。

```bash
claude --plugin-dir "F:\StudyFolder\StudyDest\project\compound-engineering-plugin-private\plugins\compound-engineering"
```

| 优点 | 说明 |
|------|------|
| **即时生效** | 修改插件后重启即可 |
| **无需配置** | 不需要修改任何配置文件 |
| **多插件支持** | 可多次使用 `--plugin-dir` 加载多个插件 |
| **官方支持** | 这是官方文档推荐的开发方式 |

### 加载多个本地插件

```bash
claude --plugin-dir ./plugin-one --plugin-dir ./plugin-two
```

### 创建快捷启动脚本

在项目根目录创建 `start-claude.ps1`：

```powershell
# start-claude.ps1
claude --plugin-dir "$PSScriptRoot\plugins\compound-engineering"
```

或创建 `start-claude.bat`：

```batch
@echo off
claude --plugin-dir "%~dp0plugins\compound-engineering"
```

---

## 通过 Marketplace 安装（分发用）

如果你想通过 marketplace 分发插件给其他用户，需要：

1. 将插件推送到 GitHub 仓库
2. 用户添加 marketplace 并安装

### 添加 Marketplace

使用 HTTPS URL（避免 SSH 认证问题）：

```
/plugins
# 选择 Add marketplace
# 输入 GitHub 仓库路径：Jerrylalala/compound-engineering-plugin-private
```

### SSH 认证失败的解决方法

如果遇到 SSH 认证错误：

```
Failed to refresh marketplace: SSH authentication failed
```

**解决方案：**

1. **方案 A：使用本地开发模式**（推荐）

   直接使用 `--plugin-dir` 启动，不需要 marketplace：
   ```bash
   claude --plugin-dir "本地路径\plugins\compound-engineering"
   ```

2. **方案 B：配置 SSH 密钥**

   确保你的 SSH 密钥已添加到 GitHub：
   ```bash
   ssh -T git@github.com
   ```

3. **方案 C：删除并重新添加 marketplace**

   在 `/plugins` 菜单中选择 Remove marketplace，然后重新添加。

---

## 验证安装

加载插件后，验证以下内容：

1. **输入 `/help`**

   应该看到 `compound-engineering` 的命令列表，如：
   - `/compound-engineering:workflows:plan`
   - `/compound-engineering:workflows:work`
   - 等等

2. **测试命令**
   ```
   /compound-engineering:workflows:plan 测试功能
   ```

3. **检查技能**

   在对话开头的 system-reminder 中应该看到 compound-engineering 的技能列表

---

## 常见问题

### Q：`/plugins install-local` 命令存在吗？

A：**不存在**。这是之前的错误信息。正确的本地开发方式是使用 `--plugin-dir` 标志启动 Claude Code。

### Q：为什么 superpowers 的技能没出现在 `~/.claude/skills/` 目录？

A：因为**插件的技能不会复制到 skills 目录**。插件技能存放在：
```
~/.claude/plugins/cache/插件来源/插件名/版本/skills/
```

调用时使用 `插件名:技能名` 格式，如 `superpowers:brainstorming`。

### Q：`~/.claude/skills/` 里的技能是从哪来的？

A：这些是**手动添加**的独立技能，不是来自任何插件。

### Q：修改插件后怎么生效？

A：重启 Claude Code 即可。如果使用 `--plugin-dir`，每次启动都会读取最新内容。

### Q：如何查看插件的所有命令？

A：查看项目的 `commands/` 目录：
```
plugins/compound-engineering/commands/
├── workflows/          # 工作流命令
│   ├── plan.md        → /compound-engineering:workflows:plan
│   ├── work.md        → /compound-engineering:workflows:work
│   ├── review.md      → /compound-engineering:workflows:review
│   └── compound.md    → /compound-engineering:workflows:compound
└── *.md               # 其他命令
```

---

## 相关文件位置

| 内容 | 路径 |
|------|------|
| 已安装插件配置 | `~/.claude/plugins/installed_plugins.json` |
| Marketplace 配置 | `~/.claude/plugins/known_marketplaces.json` |
| 插件缓存 | `~/.claude/plugins/cache/` |
| 独立技能 | `~/.claude/skills/` |
| 本地插件源 | `F:\StudyFolder\StudyDest\project\compound-engineering-plugin-private\plugins\compound-engineering` |

---

## 参考资料

- [Create plugins - Claude Code Docs](https://code.claude.com/docs/en/plugins)
- [claude-code/plugins/README.md](https://github.com/anthropics/claude-code/blob/main/plugins/README.md)

---

## 更新日志

### 2026-01-31（修订）
- **修正安装方法**：使用 `--plugin-dir` 标志，而非不存在的 `/plugins install-local`
- 添加快捷启动脚本示例
- 添加 SSH 认证失败的解决方案
- 更新命令格式（带插件前缀）

### 2026-01-31（初版）
- 首次记录安装流程
- 解释技能/插件/命令的区别
