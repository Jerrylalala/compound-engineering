---
id: "fn-01"
name: "隐蔽的 SQL 注入：sanitize_sql_like 参数顺序错误"
dimension: false-negative
difficulty: hard
target_agents:
  - security-sentinel
  - data-integrity-guardian
target_tier: blocking
tags: [security, sql-injection, rails]
fixture: "hidden-sqli.rb"
context: ""
expected_finding_count: "1-3"
expected_conclusion: finding
expected_types: [risk]
must_not_contain: []
scoring:
  - metric: true_positive_count
    pass_if: ">= 1"
  - metric: finding_specificity
    pass_if: "mentions SQL injection or 参数化"
---

## 场景描述

Rails 控制器中使用了 `sanitize_sql_like`，表面上看已经做了防注入处理。但参数传递链中有一个微妙的错误：`sanitize_sql_like` 的返回值被丢弃，原始的 `params[:q]` 仍然被拼接进 SQL 字符串。

这是一个典型的"看起来安全但实际不安全"的案例，测试 agent 是否能穿透表面的安全措施。

## 输入说明

`fixtures/hidden-sqli.rb` 包含一个 Rails 控制器方法：

```ruby
def search
  sanitized = sanitize_sql_like(params[:q])
  # 错误：使用了 params[:q] 而非 sanitized
  @results = Product.where("name LIKE '%#{params[:q]}%'")
end
```

关键点：`sanitized` 变量被创建但从未使用。

## 预期行为

- 至少 1 个 finding 指出 SQL 注入漏洞
- finding 应指出 `sanitized` 未被使用，实际查询仍使用了原始参数
- confidence 应为 high
- type 应为 risk

## 评判标准

| 条件 | 结果 |
|------|------|
| 发现 SQL 注入且指出 sanitized 变量未使用 | pass (1.0) |
| 发现 SQL 注入但未指出根因 | partial pass (0.7) |
| 仅指出"建议使用参数化查询"但未识别为漏洞 | partial pass (0.3) |
| 未发现任何 SQL 相关问题 | fail |

## 关联经验

无直接关联。此案例为合成构造。
