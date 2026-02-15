---
name: workflows:doctor
description: "独立工具: 健康检查与自动配置：检测 CLI 工具、MCP 服务器、认证状态，支持一键修复"
argument-hint: "[--fix] [--smoke]"
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

### Step 1: 运行检测脚本

确定项目根目录（包含 `scripts/doctor.sh` 的目录），然后执行：

```bash
# 自动修复模式
bash scripts/doctor.sh --fix

# 自动修复 + 冒烟测试
bash scripts/doctor.sh --fix --smoke

# 仅检测（默认）
bash scripts/doctor.sh

# 检测 + 冒烟测试
bash scripts/doctor.sh --smoke
```

使用 Bash 工具执行，设置 **60 秒**超时（默认模式）或 **120 秒**超时（`--smoke` 模式）。

根据 `$ARGUMENTS` 传递对应参数：
- 包含 `--fix` → 传递 `--fix`
- 包含 `--smoke` → 传递 `--smoke`

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
