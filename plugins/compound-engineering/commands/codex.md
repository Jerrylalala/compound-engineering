---
name: codex
description: 向 Codex 寻求更优方案和最优解
argument-hint: "[你的问题]"
claude-code-only: true
disable-model-invocation: true
---

# Codex 上下文感知咨询

<!-- SYNC: Step 1/2/4 的设计与 gemini.md 保持同步。修改时需同时更新。 -->

向 Codex 寻求当前问题的更优方案。核心目的：**挑战现有方案，寻找最优解**。

## Step 1: 构建结构化 prompt

分析当前对话上下文，智能构建 prompt。**必须附上 Claude 当前方案**供 Codex 评判。

```
## 项目背景
[技术栈、框架]

## 当前问题
[从对话中提取的问题描述]

## 相关代码
[关键代码片段，标注文件路径和行号]

## 错误信息（如有）
[错误日志/堆栈]

## 当前方案（Claude 的建议）
[Claude 已给出的方案]

## 需要你回答的问题
$ARGUMENTS

## 请特别评估
1. 当前方案是否是最优解？如果不是，更好的方案是什么？
2. 有没有我们忽略的替代方案或开源库？
3. 性价比方面：是否存在更简洁、更高效的实现方式？
4. 有没有潜在的坑或者长期维护风险？
```

只包含与问题相关的上下文，不要倾倒整个对话。

## Step 2: 调用 Codex CLI

使用 heredoc 避免特殊字符问题，通过 `codex exec` 非交互模式调用：

> **模型策略**：本项目统一使用 `gpt-5.4`（Codex 当前最新模型）。
> 不使用 gpt-4.1 等旧版本（ChatGPT 账户不支持）。
> 如需覆盖：`export CODEX_MODEL=gpt-5.4`（保持默认即可）。

```bash
CODEX_OUTPUT="${TEMP:-/tmp}/codex-ask-$(date +%s).md"
# 不指定 model 参数，使用 Codex 默认（当前为 gpt-5.4）
# 如需显式指定：codex exec -c "model=${CODEX_MODEL:-gpt-5.4}" ...
cat <<'PROMPT_EOF' | codex exec --output-last-message "$CODEX_OUTPUT" -
<构建好的prompt>
PROMPT_EOF
echo "---EXIT_CODE: $?---"
cat "$CODEX_OUTPUT" 2>/dev/null
```

使用 Bash 工具执行，设置 **300 秒**超时。

从 `$CODEX_OUTPUT` 文件读取 Codex 的回答。

**如果失败**：
- 模型不支持 → 检查 `codex --version`，运行 `npm update -g @openai/codex` 升级
- 显式指定模型（当需要覆盖时）：`codex exec -c "model=gpt-5.4" ...`
- 未安装 → 提示：`npm install -g @openai/codex`
- 网络/认证问题 → 运行 `codex login` 重新认证
- 沙箱权限 → 确保 ~/.codex/config.toml 中 [windows] sandbox = "elevated"
- 输出文件不存在 → Codex 可能未正常返回，建议重试
- 运行 `/workflows:doctor` 进行完整健康检查

## Step 3: 综合回答

```
## Codex 的方案
[Codex 的完整回答]

disable-model-invocation: true
---

## 方案对比与最优解分析

### 是否有更优方案？
[基于 Codex 反馈判断]

### 性价比评估
[实现复杂度、维护成本、性能]

### 两方一致的观点
- [共识要点，可信度更高]

### 分歧与取舍（如有）
- [各自理由和适用场景]

### 最终建议
[综合两方观点的最优解推荐]
```

如果 Codex 提出了更好的方案，诚实承认并推荐采纳。不为面子辩护，只看方案本身的优劣。
