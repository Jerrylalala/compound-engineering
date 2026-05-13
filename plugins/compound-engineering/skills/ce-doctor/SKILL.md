---
name: ce:doctor
description: "健康检查：检测 CLI、MCP、认证状态，支持一键修复"
argument-hint: "[--fix=自动修复必需项] [--smoke=执行冒烟测试]"
claude-code-only: true
disable-model-invocation: true
---

# Doctor 健康检查与自动配置

检测 CLI 工具（Codex/Gemini）、MCP 服务器（GitHub/Context7）、认证状态，支持 `--fix` 一键自动修复。

## 参数说明

- **无参数**：仅检测并报告（快速模式）
- **`--fix`**：自动安装缺失的必需项（Codex CLI、Gemini CLI、GitHub MCP）
- **`--smoke`**：额外执行冒烟测试验证 CLI 可用性
- `--fix` 和 `--smoke` 可组合使用

## 执行步骤

### Step 1: 运行健康检查

直接调用现有脚本（不依赖不存在的 doctor.sh）：

**版本一致性检查**（始终执行）：
```powershell
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1
```

**CLI 工具检查**（始终执行）：
```bash
# 检查 Codex
command -v codex && codex --version 2>/dev/null || echo "FAIL: Codex 未安装"

# 检查 Gemini
command -v gemini && gemini --version 2>/dev/null || echo "FAIL: Gemini 未安装"

# 检查 GitHub CLI
gh --version 2>/dev/null || echo "FAIL: GitHub CLI 未安装"
```

**MCP 服务器检查**（始终执行）：
```bash
# 检查 GitHub MCP
claude mcp list 2>/dev/null | grep -i github || echo "WARN: GitHub MCP 未配置"

# 检查 Context7 MCP
claude mcp list 2>/dev/null | grep -i context7 || echo "WARN: Context7 MCP 未配置"
```

**Handoff 协议检查**（始终执行）：
```bash
bash scripts/check-handoff.sh
```

如果 `$ARGUMENTS` 包含 `--smoke`，额外执行：
```bash
# 冒烟测试：验证 Codex 可执行简单任务
echo "echo hello" | codex exec - 2>/dev/null && echo "PASS: Codex smoke test" || echo "FAIL: Codex smoke test"
```

如果 `$ARGUMENTS` 包含 `--fix`，对 FAIL 项给出修复命令（见 Step 3）。

### Step 2: 格式化输出

将脚本输出格式化为 Markdown 表格展示给用户：

```markdown
## 健康检查报告

| 状态 | 检查项 | 详情 |
|------|--------|------|
| PASS | Codex CLI | 已安装 (x.x.x) |
| PASS | Gemini CLI | 已安装 (x.x.x) |
| PASS | GitHub MCP | 已配置（全局） |
| PASS | Context7 MCP | 已在 plugin.json 中配置 |
| WARN | agent-browser | 未安装（可选） |
| ... | ... | ... |

**汇总**: PASS: X  WARN: X  FAIL: X  FIXD: X
```

### Step 3: 给出修复建议

针对 FAIL 和 WARN 项，给出具体修复命令：

- **Codex 未安装** → `npm install -g @openai/codex`
- **Gemini 未安装** → 参考 Google 官方安装文档
- **模型过旧** → 提示编辑配置文件更新模型
- **认证缺失** → 提示运行首次登录
- **GitHub MCP 未配置** → `CLAUDECODE= claude mcp add --transport http github https://api.githubcopilot.com/mcp/`
- **agent-browser 未安装** → `npm install -g agent-browser`（可选）

提示用户可使用 `--fix` 参数自动修复必需项。

### Step 4: 自动修复后提醒

如果使用了 `--fix` 并成功修复了 MCP 配置（如 GitHub MCP），提醒用户：

> 已自动修复部分配置。MCP 服务器配置变更需要**重启 Claude Code** 才能生效。

### 注意事项

- 脚本路径相对于项目根目录
- 冒烟测试需要网络连接和有效认证
- 退出码：0=全部通过，1=有失败，2=仅警告
- `--fix` 不会自动安装可选项（如 agent-browser），仅安装必需项
- GitHub MCP 安装后需重启 Claude Code 才能使用
