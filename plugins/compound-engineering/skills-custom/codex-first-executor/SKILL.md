---
name: codex-first-executor
description: "私有 Overlay：Codex-first 外部执行器策略。按任务特征路由到 Claude 或 Codex，Codex-first（非品牌路由）。使用时机：需要决定是否将当前任务派发给 Codex 时加载此 skill。"
---

# Codex-first External Executor — 任务特征路由

> **Codex 洞察（P7，P5+P8 合并）**：路由策略和执行器可靠性不可分。
> 这不是「Codex 优先」品牌路由，而是「按任务特征选择最合适的执行器」。

---

## 前置条件

**必须先通过 Executor Capability Gate 检查**（skills-custom/executor-capability-gate）再执行路由决策。

---

## 任务特征路由矩阵（Dispatch Policy Matrix）

| 任务特征 | 推荐执行器 | 理由 |
|---------|-----------|------|
| **高风险改动**（auth、payment、migration、production data） | Claude 主做 + ce:review | 需要项目上下文和谨慎判断 |
| **大量机械 patch**（格式化、重命名、批量模板替换） | Codex | 重复性操作，Codex 擅长 |
| **前端视觉任务**（UI 组件、CSS） | Claude + design contract + UI Review Contract | 需要视觉理解 |
| **纯分析/代码审查** | Codex 交叉审核（[C] 参数） | 补充视角，有价值 |
| **跨文件重构**（需要项目上下文） | Claude 主做 | 上下文依赖强 |
| **独立算法实现**（无上下文依赖） | Codex（可选） | 相对独立，Codex 可胜任 |
| **文档写作/注释** | Codex（可选） | 相对机械 |

---

## 执行器可靠性管理

### 重试策略

```
调用 Codex
    ├─ 成功（exit 0）→ 使用结果
    ├─ 失败（exit 1, 网络错误）→ 等待 30s，重试 1 次
    ├─ 重试失败 → 降级到 Claude 执行
    └─ Rate limit (429) → 等待 retry-after header 时间，或降级
```

### 超时管理

```bash
# Codex 调用超时（180s）
timeout 180 codex -- "$TASK_PROMPT"
EXIT_CODE=$?
if [ $EXIT_CODE -eq 124 ]; then
  echo "Codex 超时，降级到 Claude 执行"
elif [ $EXIT_CODE -eq 0 ]; then
  # 成功调用后记录时间（供 executor-capability-gate Check 4 Rate Limit 使用）
  date +%s > ~/.codex/.last_call
fi
```

### 降级路径

```
Codex → Claude (降级)
    触发条件：CLI 不可用 / 超时 / rate limit / 任务不适合
    降级后：记录降级原因到 state.md（如有 Task Bundle）
```

---

## Codex 审核模式（[C] 参数）

当用户使用 `ce:review [C]` 或 `ce:brainstorm [C]` 时，Codex 作为**交叉审核视角**，不是主执行器：

```
Claude 执行主任务
    ↓
Claude 生成结果/审核报告
    ↓
Codex 独立审核（仅审核，不修改代码）
    ↓
多模型仲裁（Review Contract 定义的权重）
    ├─ Claude trust_score: 1.0
    └─ Codex trust_score: 0.85
    ↓
合并结论（多方一致 → confidence: high）
```

---

## Gemini 策略

> **架构澄清**：Gemini 有两种使用模式，定位不同：

| 模式 | 状态 | 入口 |
|------|------|------|
| **审核视角**（交叉审核，不执行代码） | ✅ 已激活 | `ce:review [G]`、`ce:brainstorm [G]` |
| **执行器路由**（Gemini 作为主执行引擎） | ⏸ 暂缓 | 无 |

**当前决策**：
- `[G]` 审核参数已可用：Gemini 作为独立视角交叉审核 PR 或方案，结果整合进 review/brainstorm 报告
- Gemini 作为**主线执行器**（类似 Codex 替代 Claude 执行任务）暂不实现
- 本 Executor 路由矩阵目前只路由 Claude ↔ Codex，不包含 Gemini 执行路径

---

## 与 ce:work 的集成

在 ce:work Phase 1（任务列表创建后），根据任务特征决定路由：

```
任务列表创建完成
    ↓
Intent Gate 分类意图
    ↓
Codex-first Executor 路由决策
    ├─ Claude 执行 → 继续 ce:work 原有流程
    └─ Codex 执行 → Executor Capability Gate → 派发 Codex → 验证结果
```

---

## 执行日志（Task Bundle 集成）

在 state.md 中记录路由决策：

```yaml
# state.md 新增字段
executor:
  decided_at: "2026-04-08T10:00:00+08:00"
  task_type: "批量 patch（重命名）"
  routed_to: "codex"
  gate_result: "all_pass"
  outcome: "success"  # success / degraded / timeout / rate_limited
```
