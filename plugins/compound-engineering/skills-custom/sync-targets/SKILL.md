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

确认当前工作目录是 `compound-engineering-plugin-private` 仓库：

```bash
# 验证插件目录存在
ls plugins/compound-engineering/.claude-plugin/plugin.json
```

### 2. 安装到 Codex

```bash
bun run src/index.ts install plugins/compound-engineering --to codex
```

输出位置: `~/.codex/`

### 3. 安装到 Gemini

```bash
bun run src/index.ts install plugins/compound-engineering --to gemini --gemini-home ~
```

输出位置: `~/.gemini/`

### 4. 验证安装

```bash
# 检查 Codex
ls ~/.codex/agents/ | head -5

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

- 此操作会覆盖目标位置的现有配置
- Gemini CLI 需要 `.gemini/GEMINI.md` 和 `.gemini/commands/*.toml`
- Codex CLI 需要 `.codex/agents/*.md` 和 `.codex/AGENTS.md`
