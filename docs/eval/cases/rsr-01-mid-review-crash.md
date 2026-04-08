---
id: "rsr-01"
name: "审查中途崩溃后从 state.md 恢复"
dimension: resume
difficulty: medium
target_agents:
  - architecture-strategist
target_tier: analytical
tags: [resume, state, crash-recovery]
fixture: "mid-review-state.md"
context: |
  state.md 记录了 5 个文件的审查进度：
  - file1.ts: reviewed, 1 finding (coupling issue)
  - file2.ts: reviewed, 1 finding (missing interface)
  - file3.ts: not started
  - file4.ts: not started
  - file5.ts: not started
  FSM 状态：active
expected_finding_count: "3-6"
expected_conclusion: finding
expected_types: [exists, missing, risk]
must_not_contain: []
scoring:
  - metric: resume_success
    pass_if: "== true"
  - metric: no_duplicate_review
    pass_if: "file1 and file2 not re-reviewed"
  - metric: recovery_ratio
    pass_if: ">= 0.8"
---

## 场景描述

architecture-strategist 正在审查一个 5 文件的 PR，完成了 2 个文件的审查并产出了 2 个 finding。此时会话中断（模拟崩溃）。

恢复时提供 state.md 和已产出的 2 个 finding。agent 需要：
1. 理解已完成的进度
2. 从第 3 个文件继续
3. 最终产出包含所有 finding（已有 + 新发现）的完整报告

## 输入说明

`fixtures/mid-review-state.md` 包含：
- Task Bundle 格式的 state.md
- 已审查文件列表和状态
- 已产出的 2 个 Structured Finding
- 待审查文件列表

## 预期行为

- 从 file3.ts 开始继续审查，不重复 file1/file2
- 最终报告包含 2 个已有 finding + 新发现
- 报告结构完整，不因恢复而格式混乱

## 评判标准

| 条件 | 结果 |
|------|------|
| 从 file3 继续 + 包含已有 finding + 格式完整 | pass |
| 重新审查了 file1/file2 但结果一致 | partial pass (0.6)（浪费但不错） |
| 丢失了已有的 2 个 finding | fail |
| 从 file1 重新开始且结果不同 | fail |

## 关联经验

Failure FSM 协议：active 状态下的中断恢复。
