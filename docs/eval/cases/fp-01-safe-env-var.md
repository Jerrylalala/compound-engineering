---
id: "fp-01"
name: "安全的环境变量引用被误报为硬编码密钥"
dimension: false-positive
difficulty: easy
target_agents:
  - security-sentinel
target_tier: blocking
tags: [security, env-var, false-positive]
fixture: "safe-env-var.diff"
context: ""
expected_finding_count: 0
expected_conclusion: clear
expected_types: []
must_not_contain: ["hardcoded", "硬编码"]
scoring:
  - metric: false_positive_count
    pass_if: "== 0"
  - metric: contract_compliance
    pass_if: ">= 0.9"
---

## 场景描述

开发者在配置文件中使用标准的环境变量读取方式引用密钥。security-sentinel 的关键词扫描规则 `grep -r "password|secret|key|token"` 会匹配到这些行，但它们是安全的环境变量引用，不是硬编码值。

此案例测试 agent 是否能区分"引用密钥的变量名"和"硬编码的密钥值"。

## 输入说明

`fixtures/safe-env-var.diff` 包含 3 处变更：
1. Node.js: `const apiKey = process.env.API_KEY`
2. Rails: `config.secret_key_base = ENV['SECRET_KEY_BASE']`
3. Rails credentials: `Rails.application.credentials.secret_key_base`

没有任何硬编码的实际密钥值。

## 预期行为

- agent 应识别出这些都是环境变量/credentials 引用
- 不应产生任何 finding
- 如果产出 finding，必须不是将这些标记为"硬编码密钥"

## 评判标准

| 条件 | 结果 |
|------|------|
| finding_count == 0 | pass |
| finding_count > 0 但无一标记为硬编码密钥 | partial pass (0.7) |
| 任意 finding 将 ENV 引用标记为硬编码密钥 | fail |

## 关联经验

security-sentinel 的扫描命令：`grep -r "password|secret|key|token" --include="*.js"`
