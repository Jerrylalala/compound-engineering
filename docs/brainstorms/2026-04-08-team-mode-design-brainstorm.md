# Team Mode Design Brainstorm

**Date**: 2026-04-08  
**Topic**: [team] 参数 — 多代理协作模式设计  
**Method**: Party Mode [P] + Codex 深度分析 [C]  
**Participants**: 李明远（架构师）、苏质量（QA）、张晓峰（开发者）+ Codex gpt-5.4

---

## What We're Building

为 compound-engineering 插件的主流程命令（brainstorm/plan/work/review）添加统一的 `[team]` 参数，开启多代理协作模式。

**核心诉求**：又快又稳。执行已经够快，但每次 review 都能发现大量问题，autofix 还会把好的代码改坏。

**不是**：Swarm 并行加速（那是 [swarm] 的职责）  
**是**：执行时并行引入验证和边界守护，把问题前移拦截

---

## Why This Approach

### 根因分析

当前不稳定的根因（Codex 读源码后确认）：

1. **没有单写者原则** — 多个逻辑上的"修改者"可能同时作用于代码
2. **没有合约白名单** — autofix 不知道哪些文件不该碰
3. **验证滞后** — 问题在所有任务完成后才被 ce:review 发现，返工成本高
4. **patch 粒度太粗** — 一次 autofix 改多处，出错难以定位和回滚

### 关键洞察（Codex）

> "不要把'稳'主要押在更多 agent 上，要押在`单写者 + 合约白名单 + deterministic patch gate + 独立验证`上。"

现有 `patch-approval` 和 `review-contract` overlay 方向正确，但"入口未接通、职责重复、虚拟字段无消费者"——**不是缺角色，是现有机制没有串联**。

---

## Key Decisions

### 决策1：按阶段用不同角色集（不是一套角色铺满所有阶段）

| 阶段 | 默认角色 | tmux短名 | 高风险时加 |
|------|---------|----------|-----------|
| `/ce:brainstorm [team]` | 探索者 + 挑战者 | `探索` `挑战` | 可行性审查 |
| `/ce:plan [team]` | 合约主 + 追溯审 | `合约` `追溯` | 风险审查 |
| `/ce:work [team]` | 合约主 + 执行者 + 验证者 | `合约` `执行` `验证` | 风险卫 |
| `/ce:review [team]` | 已有31个审查agent，[team] 叠加合约门控 | — | — |

### 决策2：work 阶段四个角色的中文名与职责

| 中文名 | tmux短名 | 职责 | 生命周期 |
|-------|---------|------|---------|
| **合约主** | `合约` | 执行前写边界合约（允许文件、禁止操作、不变式），全程持有合约权威 | 全程存活，不是写完就消失的 Planner |
| **执行者** | `执行` | **唯一可以写共享代码的角色**（单写者原则），遇越界暂停上报 | 按任务运行 |
| **验证者** | `验证` | 每单元完成后跑集成验证，只读不写，发现回归立即报警 | 事件驱动 |
| **风险卫** | `风险` | 专门拦截高风险路径（auth/payment/migration），仅 full 模式启用 | 仅 full 模式 |

### 决策3：参数设计

```bash
# work 阶段（核心）
/ce:work [team]           → 3角色：合约主 + 执行者 + 验证者（默认）
/ce:work [team:light]     → 2角色：执行者 + 验证者（快速小任务）
/ce:work [team:full]      → 4角色：全部（auth/payment/migration等高风险）

# brainstorm 阶段（与已有 [P] 区分）
/ce:brainstorm [P]        → Party Mode：14位专家自由讨论（已有）
/ce:brainstorm [team]     → 结构化探索：探索者 + 挑战者（有明确退出和聚焦条件）

# plan 阶段
/ce:plan [team]           → 合约主 + 追溯审查

# review 的 autofix（重要：保留现有语义）
/ce:review mode:autofix [team]  → 现有 mode:autofix + 合约白名单门控
# ⚠️ 不要用 [fix] 替换 mode:autofix——Codex 确认会与现有协议冲突
```

### 决策4：autofix 越界的根本解法（规则优于角色）

把"审计者"从"常驻思考 agent"降为"deterministic patch gate"（规则引擎）：

```
合约白名单机制：
  plan 阶段 → 合约主写入 .team-contract.md：
    allowed_files: [...]
    forbidden_surfaces: ["db/schema.rb", "权限相关文件"]
    required_invariants: ["改完必须有对应测试", "不能移除已有测试"]

autofix 写入前 deterministic 检查（无需 agent，规则即可）：
  if patch.files ⊄ allowed_files → 降为 gated_auto，不自动写入
  if patch.touches forbidden_surface → 拒绝
  if patch.requires_verification → 先跑测试再落盘
  if patch.file_count > threshold → 拒绝（强制人工审查）
```

**one finding → one patch**：每个发现对应一个最小 patch，便于回滚和归因。

**隔离 worktree 产 patch**：在隔离副本生成 fix，看 diff 决定是否合并到主 checkout。

### 决策5：单写者原则（最关键的架构约束）

> 只有**执行者**可以写共享 checkout。其他角色（合约主、验证者、风险卫）只读，或在隔离 worktree 工作。

这一条比增加任何 agent 更能提升稳定性。

---

## Approaches Considered

### 方案A：固定4角色（规划者/执行者/审计者/守卫者）
- 优点：职责清晰
- **缺点**：70%中小任务协调成本 > 收益；Fix Auditor 常驻太晚介入且 token 浪费；用户感觉重，会绕开

### 方案B：3角色默认 + 4角色可选（本方案）✅
- 优点：按风险形状缩放；合约白名单替代常驻 Fix Auditor；单写者原则从架构层解决稳定性
- 缺点：需要实现合约文件的生成和读取机制

### 方案C：仅2角色（执行者+验证者）
- 优点：最省 token
- **缺点**：没有合约主，越界修复问题无法从根本解决

---

## Open Questions

1. **合约文件格式**：`.team-contract.md` 用 YAML frontmatter 还是纯 Markdown 表格？需要 ce:plan 阶段自动生成还是手动填写？
2. **tmux 集成**：如何让每个角色的输出路由到对应窗格？是否需要一个 coordinator 脚本？
3. **brainstorm [team] vs [P] 的边界**：[P] 是发散探索，[team] 是收敛验证，两者可以组合吗？`[P][team]`？
4. **合约主的"持续存在"机制**：在 Claude Code 里，合约主是独立 subagent 还是通过文档持久化？

---

## Next Step

进入 `/ce:plan` 规划实现，优先级：
1. `合约主` 角色定义 + `.team-contract.md` 格式设计
2. `[team]` 参数解析（扩展现有各命令的参数解析逻辑）
3. `deterministic patch gate` 集成到 ce:review 的 autofix 路径
4. `单写者原则` 在 ce:work 中的强制实现
5. brainstorm/plan 阶段的对应角色集定义
