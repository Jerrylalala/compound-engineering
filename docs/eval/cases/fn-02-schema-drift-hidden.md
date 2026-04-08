---
id: "fn-02"
name: "隐蔽的 schema drift：少量无关 column 混入"
dimension: false-negative
difficulty: medium
target_agents:
  - schema-drift-detector
target_tier: advisory
tags: [schema, drift, rails, migration]
fixture: "schema-drift.diff"
context: |
  PR 包含 1 个 migration：add_column :users, :avatar_url, :string
  schema.rb diff 中有 3 行变更，其中 1 行是 avatar_url（正确），2 行是 legacy_flag 和 temp_score（无关 drift）
expected_finding_count: "1-2"
expected_conclusion: finding
expected_types: [risk]
must_not_contain: []
scoring:
  - metric: drift_columns_identified
    pass_if: ">= 1"
  - metric: correct_column_not_flagged
    pass_if: "avatar_url not in drift list"
---

## 场景描述

开发者提交了一个简单的 migration（添加 `avatar_url` 列），但 `schema.rb` 的 diff 中混入了两个不属于本 PR 的列变更：`legacy_flag` 和 `temp_score`。这些是开发者在 main 分支上运行其他 migration 后切换回功能分支时带入的。

drift 只有 2 行，在整个 diff 中不显眼，容易被忽略。

## 输入说明

`fixtures/schema-drift.diff` 包含：
- migration 文件：`add_column :users, :avatar_url, :string`
- schema.rb diff：3 处 column 变更（avatar_url + legacy_flag + temp_score）

## 预期行为

- 识别出 `legacy_flag` 和 `temp_score` 不属于本 PR 的 migration
- 不应将 `avatar_url` 标记为 drift
- 建议开发者运行 `git checkout main -- db/schema.rb` 然后重新执行 migration

## 评判标准

| 条件 | 结果 |
|------|------|
| 正确识别 2 个 drift column 且未误标 avatar_url | pass |
| 正确识别 1 个 drift column | partial pass (0.7) |
| 将 avatar_url 也标记为 drift | fail（误报） |
| 未发现任何 drift | fail（漏报） |

## 关联经验

schema-drift-detector.md 描述的核心问题场景。
