---
name: gemini
description: 向 Gemini 寻求更优方案和最优解
argument-hint: "[你的问题]"
claude-code-only: true
disable-model-invocation: true
---

# Gemini 上下文感知咨询

<!-- SYNC: Step 1/2/4 的设计与 codex.md 保持同步。修改时需同时更新。 -->

向 Gemini 寻求当前问题的更优方案。核心目的：**挑战现有方案，寻找最优解**。

## Step 1: 构建结构化 prompt

分析当前对话上下文，智能构建 prompt。**必须附上 Claude 当前方案**供 Gemini 评判。

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

## Step 2: 调用 Gemini CLI

使用 heredoc 避免特殊字符问题，通过非交互模式调用：

```bash
# -m gemini-3-pro-preview: 使用 Gemini 3 Pro 最新模型
# -p '': 非交互模式，stdin 内容作为 prompt
# -o json: JSON 格式输出，提取 .response 字段
cat <<'PROMPT_EOF' | gemini -m gemini-3-pro-preview -p '' -o json
<构建好的prompt>
PROMPT_EOF
```

> **安全提示**：`-p` 仅控制 prompt 输入方式，不限制执行权限。Gemini 在此模式下仍可能尝试工具调用。当前通过 Claude Code 的 Bash 工具执行，由 Claude Code 控制实际权限边界。

使用 Bash 工具执行，设置 **300 秒**超时。

解析返回的 JSON，提取 `.response` 字段。

**如果失败**：
- 未安装 → 提示：`npm install -g @google/gemini-cli`
- 网络/认证问题 → 提示检查 Google API 配置
- JSON 解析失败 → 直接展示原始输出

## Step 3: 综合回答

```
## Gemini 的方案
[Gemini 的完整回答]

disable-model-invocation: true
---

## 方案对比与最优解分析

### 是否有更优方案？
[基于 Gemini 反馈判断]

### 性价比评估
[实现复杂度、维护成本、性能]

### 两方一致的观点
- [共识要点，可信度更高]

### 分歧与取舍（如有）
- [各自理由和适用场景]

### 最终建议
[综合两方观点的最优解推荐]
```

如果 Gemini 提出了更好的方案，诚实承认并推荐采纳。不为面子辩护，只看方案本身的优劣。
