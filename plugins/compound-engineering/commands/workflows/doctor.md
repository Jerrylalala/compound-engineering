---
name: workflows:doctor
description: "健康检查：检测 Codex/Gemini CLI 安装、模型版本和认证状态"
argument-hint: "[--smoke]"
claude-code-only: true
disable-model-invocation: true
---

# Doctor 健康检查

检测 Codex/Gemini CLI 的安装状态、模型版本和认证配置。

## 执行步骤

### Step 1: 运行检测脚本

确定项目根目录（包含 `scripts/doctor.sh` 的目录），然后执行：

```bash
# 如果用户传了 --smoke 参数
bash scripts/doctor.sh --smoke

# 默认（快速模式，不含冒烟测试）
bash scripts/doctor.sh
```

使用 Bash 工具执行，设置 **60 秒**超时（默认模式）或 **120 秒**超时（`--smoke` 模式）。

如果 `$ARGUMENTS` 包含 `--smoke`，传递 `--smoke` 参数。

### Step 2: 格式化输出

将脚本输出格式化为 Markdown 表格展示给用户：

```markdown
## 健康检查报告

| 状态 | 检查项 | 详情 |
|------|--------|------|
| PASS | Codex CLI | 已安装 (x.x.x) |
| PASS | Gemini CLI | 已安装 (x.x.x) |
| ... | ... | ... |

**汇总**: PASS: X  WARN: X  FAIL: X
```

### Step 3: 给出修复建议

针对 FAIL 和 WARN 项，给出具体修复命令：

- **Codex 未安装** → `npm install -g @openai/codex`
- **Gemini 未安装** → 参考 Google 官方安装文档
- **模型过旧** → 提示编辑配置文件更新模型
- **认证缺失** → 提示运行首次登录

### 注意事项

- 脚本路径相对于项目根目录
- 冒烟测试需要网络连接和有效认证
- 退出码：0=全部通过，1=有失败，2=仅警告
