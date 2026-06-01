# sync-targets

将本地 compound-engineering 插件同步安装到 Codex CLI 和 Gemini CLI。

## 使用场景

当用户说以下内容时触发此技能：
- "同步到 Gemini"
- "同步到 Codex"
- "安装到 Gemini 和 Codex"
- "更新 Gemini 配置"
- "sync to targets"

## 执行流程

### 1. 确认当前仓库

确认当前工作目录是 `compound-engineering` 仓库：

```bash
# 验证插件目录存在
ls plugins/compound-engineering/.claude-plugin/plugin.json
```

### 2. 同步到 Codex

**注意**：此操作只同步 3 个 Codex 兼容入口 workflow skill（brainstorm/plan/review），不安装整个插件。

```powershell
powershell -ExecutionPolicy Bypass -File scripts/sync-codex-workflows.ps1
```

输出位置: `~/.codex/skills/workflows-{brainstorm,plan,review}/`

### 3. 安装到 Gemini

```bash
bun run src/index.ts install plugins/compound-engineering --to gemini --gemini-home ~
```

输出位置: `~/.gemini/`

### 4. 验证安装

```bash
# 检查 Codex
ls ~/.codex/skills/ | head -5

# 检查 Gemini
ls ~/.gemini/GEMINI.md
ls ~/.gemini/commands/ | head -5
```

## 一键命令（Windows PowerShell）

```powershell
powershell -ExecutionPolicy Bypass -File scripts/sync-to-targets.ps1
```

## 参数说明

| 参数 | 说明 |
|------|------|
| `-GeminiHome` | Gemini 输出目录，默认 `$HOME` |
| `-CodexOnly` | 只安装到 Codex |
| `-GeminiOnly` | 只安装到 Gemini |

## 注意事项

- 此操作面向维护者本机同步，会覆盖目标位置的同名插件配置
- Gemini CLI 需要 `.gemini/GEMINI.md` 和 `.gemini/commands/*.toml`
- Codex CLI 需要 `.codex/skills/*/SKILL.md`；完整 CLI 安装还会写入 `.codex/prompts/*.md` 和 `.codex/AGENTS.md`
