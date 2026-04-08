---
team_mode: true
generated_by: "ce:plan [team]"
generated_at: YYYY-MM-DD
plan_source: PLAN_PATH
plan_source_commit: null   # 由 ce:plan 自动填充：git log -1 --format='%H' -- <plan_source>
allowed_files: []
forbidden_surfaces: []
required_invariants: []
max_files_per_patch: 1
last_verification_failure: null
---

# Team Contract

## 背景

<!-- 可选：描述本次任务的背景、边界约束、以及为什么这些文件被允许/禁止 -->

## 使用说明

- **allowed_files**: 执行者（ce:work）在本次任务中允许修改的文件列表
- **forbidden_surfaces**: 绝对禁止自动修改的文件（由 ce:review Patch Gate 强制执行）
- **required_invariants**: 每次变更后验证者必须检查的不变式
- **plan_source_commit**: 由 ce:plan 自动填充；ce:work 加载时对比当前 hash，检测计划是否已更新
- **max_files_per_patch**: 通常保持为 1（one-finding-one-patch 原则）
- **last_verification_failure**: 验证者自动写入，人工修复后可清空为 null
