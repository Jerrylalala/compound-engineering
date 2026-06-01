---
name: patch-approval
description: "Fork Overlay：Codex Patch Approval 咨询版。当 Codex 返回 patch 时，Claude 审批后才写入文件。使用时机：Codex 以 patch/diff 格式返回代码变更时，由 Claude 作为审批层。"
---

# Patch Approval — 咨询版

> **Codex 评分：4/10（完整版不可行）**，咨询版可行。
>
> 场景：Codex 生成 patch → Claude 审批 → 用户确认 → 写入。
> 这比「直接接受 Codex 输出」多一层安全保障。

---

## 触发条件

当满足以下条件时激活 Patch Approval：

1. 使用了 Codex 执行器（Codex-first Executor 路由到 Codex）
2. Codex 返回的是 patch/diff 格式（不是直接文件修改）
3. 任务不是纯分析（分析任务不需要审批）

---

## 审批流程

### Step 0: 在隔离目录执行 Codex

> **注意**：Codex CLI 不支持 `--dry-run` 参数（已验证 v0.118+）。
> 唯一安全方案是在临时隔离副本中执行，再用 `git diff` 捕获 patch。

```bash
# 1. 在临时目录创建仓库副本（跨平台安全路径）
ISOLATED_DIR=$(mktemp -d)
git clone . "$ISOLATED_DIR" --local --quiet

# 2. 在隔离目录执行 Codex（真实写入，不影响工作区）
(cd "$ISOLATED_DIR" && codex "$TASK_PROMPT")

# 3. 用 git diff 捕获改动作为 patch
git -C "$ISOLATED_DIR" diff HEAD > "${TMPDIR:-/tmp}/codex-patch.diff"

# 4. 清理隔离目录
rm -rf "$ISOLATED_DIR"
```

### Step 1: Codex 生成 Patch

运行 Step 0 的隔离方案，将 patch 输出到 `${TMPDIR:-/tmp}/codex-patch.diff`。

### Step 2: Claude 审批

Claude 读取 patch 内容，按以下维度评估：

```markdown
## Patch 审批检查清单

**安全维度**（Blocking）：
- [ ] 无 SQL 注入 / XSS / 命令注入
- [ ] 无硬编码密钥或敏感信息
- [ ] 无未授权的文件路径操作

**正确性维度**（Analytical）：
- [ ] 改动符合原始任务意图
- [ ] 没有意外的副作用
- [ ] 变量名/函数签名合理

**范围维度**（Advisory）：
- [ ] 改动范围在预期之内（没有多改）
- [ ] 没有删除不应删除的代码
```

### Step 3: 审批决策

| 决策 | 条件 | 行动 |
|------|------|------|
| **通过** | 所有 Blocking 检查通过 | 应用 patch |
| **修改后通过** | Analytical 有小问题 | Claude 修正 patch 后应用 |
| **拒绝** | Blocking 检查失败 | 拒绝 patch，回退到 Claude 执行 |

### Step 4: 用户确认（可选）

对于 `gated_auto` 类型的改动，展示 patch 摘要并询问确认：

```
📋 Codex Patch 摘要（已通过 Claude 审批）：

  修改 3 个文件：
  + app/models/user.rb  (2 行新增)
  ~ app/controllers/users_controller.rb  (5 行修改)
  - app/views/users/index.html.erb  (1 行删除)

  审批结论：通过（无 Blocking 问题）
  主要改动：[改动描述]

  应用此 patch？(y/n/查看详情)
```

---

## 审批记录

在 state.md 中记录审批结果（如有 Task Bundle）：

```yaml
patch_approval:
  patch_source: "codex"
  approved_at: "2026-04-08T10:00:00+08:00"
  verdict: "pass"  # pass / modified_pass / rejected
  blocking_issues: []
  modifications: []  # Claude 修正的内容
```

---

## 限制说明（咨询版）

| 限制 | 说明 |
|------|------|
| 不支持自动应用（完整版） | 每次都需要用户确认（安全考虑） |
| 不支持复杂冲突解决 | Codex patch 有冲突时回退到 Claude 执行 |
| 隔离目录方案依赖 git clone | 工作区必须是 git 仓库，且本地 clone 可用 |

---

## 与 ce:work 的集成位置

```
Codex-first Executor 路由到 Codex
    ↓
Codex 执行（dry-run 模式）
    ↓
Patch Approval（本 skill）
    ├─ 通过 → 应用 patch → 继续 ce:work
    └─ 拒绝 → 记录原因 → 降级到 Claude 执行
```
