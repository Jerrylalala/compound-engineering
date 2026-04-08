# Review Agent 评测体系设计

> 评测 15 个 review agent 在 Review Contract + Task Bundle + Failure FSM 框架下的质量。

---

## 1. 评测维度

| 维度 | 代号 | 定义 | 量化方式 |
|------|------|------|----------|
| **误报率** | `FPR` | agent 产出不成立的 finding 占总 finding 的比例 | `FP / (FP + TP)` |
| **漏报率** | `FNR` | agent 遗漏的真实问题占应发现问题总数的比例 | `FN / (FN + TP)` |
| **中断恢复成功率** | `RSR` | 从 state.md 恢复后，agent 能否产出与全量审查一致的结论 | `恢复后一致 finding 数 / 全量 finding 数` |
| **合约合规率** | `CCR` | 输出符合 Review Contract 结构化格式的比例 | `合规字段数 / 应填字段数` |
| **事实核查通过率** | `FVR` | Structured Findings 中的证据可被独立验证的比例 | `可验证 finding / 总 finding` |

---

## 2. 文件结构

```
docs/eval/
├── EVAL-DESIGN.md              # 本文件：整体设计
├── SCORING.md                  # 评分标准与阈值
├── RUNBOOK.md                  # 执行手册
├── cases/
│   ├── fp-01-safe-env-var.md           # 误报：安全的环境变量
│   ├── fp-02-yagni-plan-docs.md        # 误报：计划文档非死代码
│   ├── fn-01-sql-injection.md          # 漏报：隐蔽 SQL 注入
│   ├── fn-02-schema-drift-hidden.md    # 漏报：隐蔽 schema drift
│   ├── fn-03-race-condition.md         # 漏报：前端竞态条件
│   ├── rsr-01-mid-review-crash.md      # 中断恢复：审查中途崩溃
│   ├── rsr-02-blocked-to-resumed.md    # 中断恢复：FSM 状态转移
│   ├── ccr-01-mixed-tiers.md           # 合约合规：多 tier 混合输出
│   ├── e2e-01-full-pipeline.md         # 端到端：完整 review 流水线
│   ├── e2e-02-cross-agent-dedup.md     # 端到端：多 agent 发现去重
│   ├── al-a-vague-dismissal.md         # Anti-leniency：模糊免责拦截
│   ├── al-b-legitimate-tradeoff.md     # Anti-leniency：合理设计权衡保留
│   ├── al-c-unverified-dead-work.md    # Anti-leniency：未验证 dead work 拦截
│   └── al-d-opinion-vs-finding.md      # Anti-leniency：Opinion vs Finding 降级
├── scoreboard.md               # 历史评分记录板
├── fixtures/
│   ├── safe-env-var.diff
│   ├── plan-docs-tree.txt
│   ├── hidden-sqli.rb
│   ├── schema-drift.diff
│   ├── race-condition.tsx
│   ├── mid-review-state.md
│   ├── blocked-state.md
│   ├── multi-tier-diff.py
│   ├── full-pipeline-pr.diff
│   ├── cross-agent-pr.diff
│   ├── al-a-vague-output.json          # Anti-leniency fixture
│   ├── al-b-advisory-question.json     # Anti-leniency fixture
│   ├── al-c-unverified-clear.json      # Anti-leniency fixture
│   └── al-d-opinion-blocking.json      # Anti-leniency fixture
└── results/
    └── .gitkeep                # 评测结果存放目录（不提交具体结果）
```

---

## 3. 案例格式 Schema

每个 `cases/*.md` 文件使用以下格式：

```yaml
---
# 必填
id: "fp-01"                          # 唯一标识，前缀表维度
name: "安全的环境变量引用被误报为硬编码密钥"
dimension: false-positive             # false-positive | false-negative | resume | contract | e2e
difficulty: easy                      # easy | medium | hard

# agent 信息
target_agents:                        # 被测 agent 列表
  - security-sentinel
target_tier: blocking                 # blocking | analytical | advisory
tags: [security, env-var]

# 输入
fixture: "safe-env-var.diff"          # fixtures/ 下的输入文件
context: |                            # 可选：额外上下文（如 state.md 内容）
  无

# 预期
expected_finding_count: 0             # 预期 finding 数量（精确值或范围 "1-3"）
expected_conclusion: clear            # finding | question | needs-human-check | clear
expected_types: []                    # 预期 finding 的 type 列表
must_not_contain: ["hardcoded"]       # 输出中不应出现的关键词

# 评判
scoring:
  - metric: false_positive_count      # 具体评分指标
    pass_if: "== 0"
  - metric: contract_compliance
    pass_if: ">= 0.9"
---

## 场景描述
[自然语言描述场景、为什么这个案例重要]

## 输入说明
[fixture 文件的内容摘要和关键点]

## 预期行为
[agent 应该做什么、不应该做什么]

## 评判标准
[具体的 pass/fail 条件表格]

## 关联经验
[引用 docs/solutions/ 中的相关经验，如果有的话]
```

---

## 4. 评测案例（10 个）

### 案例 1：fp-01-safe-env-var（误报 - easy）

**维度**：FPR  
**目标 agent**：security-sentinel  
**场景**：diff 中出现 `process.env.API_KEY`、`ENV['SECRET_KEY_BASE']`、`Rails.application.credentials.secret_key_base`。security-sentinel 的关键词扫描 `grep -r "key|secret|token"` 匹配到这些行。  
**预期**：0 个 finding。agent 应识别这些是安全的环境变量引用，不是硬编码密钥。  
**pass 条件**：finding_count == 0，无 `type: risk` 的输出。

### 案例 2：fp-02-yagni-plan-docs（误报 - medium）

**维度**：FPR  
**目标 agent**：code-simplicity-reviewer  
**场景**：PR 中包含 `docs/plans/feature-x-plan.md` 和 `docs/solutions/resolved-issue.md`。code-simplicity-reviewer 可能将这些文档标记为"不必要的文件"或"YAGNI 违反"。  
**预期**：0 个针对 plan/solution 文档的 finding。agent prompt 中已有规则 "Never flag `docs/plans/*.md` or `docs/solutions/*.md` for removal"。  
**pass 条件**：无 finding 的 scope 涉及 `docs/plans/` 或 `docs/solutions/`。

### 案例 3：fn-01-sql-injection（漏报 - hard）

**维度**：FNR  
**目标 agent**：security-sentinel, data-integrity-guardian  
**场景**：Rails 控制器中使用 `where("name LIKE '%#{params[:q]}%'")`，外层被 `sanitize_sql_like` 包裹但参数传递顺序错误，实际未生效。  
**预期**：至少 1 个 `type: risk`、`confidence: high` 的 finding，指出 SQL 注入漏洞。  
**pass 条件**：finding_count >= 1，且 finding 中包含 "SQL injection" 或 "参数化查询" 关键词。

### 案例 4：fn-02-schema-drift-hidden（漏报 - medium）

**维度**：FNR  
**目标 agent**：schema-drift-detector  
**场景**：PR 包含一个 migration（add_column :users, :avatar_url）和 schema.rb diff。schema.rb 的 diff 中混入了另一个不属于本 PR 的 column（:legacy_flag），但 diff 行数较少（只有 2 行额外变更），容易被忽略。  
**预期**：至少 1 个 finding 指出 `:legacy_flag` 是无关的 schema drift。  
**pass 条件**：finding 中明确列出不属于本 PR migration 的 column 名。

### 案例 5：fn-03-race-condition（漏报 - hard）

**维度**：FNR  
**目标 agent**：julik-frontend-races-reviewer  
**场景**：React 组件在 `useEffect` 中 fetch 数据，组件卸载时未取消 AbortController，同时有 `setState` 调用。竞态：快速切换页面导致已卸载组件执行 setState。  
**预期**：至少 1 个 finding 指出 abort/cleanup 缺失导致的竞态风险。  
**pass 条件**：finding 包含 "race condition"、"abort" 或 "cleanup" 关键词。

### 案例 6：rsr-01-mid-review-crash（中断恢复 - medium）

**维度**：RSR  
**目标 agent**：architecture-strategist  
**场景**：提供一个半完成的 state.md（3/5 个文件已审查，2 个 finding 已产出），模拟审查中途崩溃。恢复后 agent 应从第 4 个文件继续，最终产出完整结果。  
**预期**：恢复后的 finding 列表包含前 2 个已有 finding + 后续新发现，不重复审查已完成的文件。  
**pass 条件**：RSR >= 0.8（恢复后结果与全量审查的 finding 重叠率）。

### 案例 7：rsr-02-blocked-to-resumed（中断恢复/FSM - hard）

**维度**：RSR  
**目标 agent**：deployment-verification-agent  
**场景**：task 状态从 `active` 进入 `blocked`（因为缺少生产环境凭证），经过 `debugging` 和 `replanned` 后进入 `resumed`。提供完整的 state.md FSM 历史。agent 需要理解当前上下文并从 resumed 状态继续审查。  
**预期**：agent 不重复之前已完成的检查，且输出中体现对 blocked 原因的理解。  
**pass 条件**：输出中引用了 blocked 原因，且未重复 blocked 之前已完成的 finding。

### 案例 8：ccr-01-mixed-tiers（合约合规 - medium）

**维度**：CCR  
**目标 agent**：security-sentinel, code-simplicity-reviewer, architecture-strategist  
**场景**：一个涉及安全、架构、简洁性三方面问题的中等大小 PR。三个 agent 分别产出 finding，需要验证所有输出是否符合 Review Contract 的 YAML 结构。  
**预期**：每个 finding 必须包含 Claim/Type/Scope/Evidence/Proposed Action/Confidence/Assumptions 全部 7 个字段。  
**pass 条件**：CCR >= 0.95（至少 95% 的字段被正确填充）。

### 案例 9：e2e-01-full-pipeline（端到端 - hard）

**维度**：全维度  
**目标 agent**：全部 15 个（通过 `/workflows:review` 调度）  
**场景**：一个真实规模的 PR diff（~200 行），包含 Rails 控制器变更、React 前端变更、migration、配置文件修改。fixture 中预埋 3 个已知问题：1 个安全漏洞（blocking）、1 个架构违反（analytical）、1 个命名不一致（advisory）。  
**预期**：blocking agent 必须发现安全漏洞，analytical agent 必须发现架构违反，advisory agent 至少有 1 个提出命名问题。  
**pass 条件**：3 个预埋问题的检出率 >= 2/3，且无严重误报（blocking tier 的 FPR == 0）。

### 案例 10：e2e-02-cross-agent-dedup（端到端 - medium）

**维度**：全维度  
**目标 agent**：security-sentinel, data-integrity-guardian, architecture-strategist  
**场景**：PR 中有一个缺少事务包裹的数据库操作。security-sentinel 可能标记为"数据一致性风险"，data-integrity-guardian 标记为"缺少事务边界"，architecture-strategist 标记为"层级违反"。三者描述的是同一个根本问题。  
**预期**：review 流水线的汇总阶段应识别出这三个 finding 指向同一根因，合并或标注关联关系。  
**pass 条件**：最终报告中相关 finding 被关联（通过 `related_to` 字段或合并叙述），而非作为 3 个独立问题呈现。

---

## 5. 评分标准与通过阈值

### 单案例评分

每个案例的评分由以下维度加权：

| 评分项 | 权重 | 计算方式 |
|--------|------|----------|
| **核心判断正确** | 50% | 预期 finding 是否被正确识别/正确忽略（二值：0 或 1） |
| **合约合规** | 20% | Structured Finding 格式完整度（0.0-1.0 连续值） |
| **证据质量** | 20% | Evidence 字段是否包含可验证的 file:line 引用（0.0-1.0） |
| **无噪声** | 10% | 无关 finding 的扣分（每个无关 finding 扣 0.1，最低 0） |

**单案例总分** = `核心判断 * 0.5 + 合约合规 * 0.2 + 证据质量 * 0.2 + 无噪声 * 0.1`

### 分维度通过阈值

| 维度 | 阈值 | 计算基数 | 不通过后果 |
|------|------|----------|------------|
| FPR（误报率） | <= 15% | 该维度所有案例的 FP/(FP+TP) | 相关 agent prompt 需加反例 |
| FNR（漏报率） | <= 10% | 该维度所有案例的 FN/(FN+TP) | 相关 agent 扫描规则需增强 |
| RSR（恢复率） | >= 80% | 恢复后 finding 与全量的一致率 | state.md 协议需修订 |
| CCR（合约合规） | >= 95% | 所有 finding 的字段完整度均值 | agent prompt 的输出模板需强化 |
| FVR（事实核查） | >= 90% | 所有 Evidence 字段的可验证率 | 事实性声明规范需加强 |

### 整体通过条件

**全部 5 个维度达标** = 评测通过。任意一个维度不达标 = 评测不通过，需修复对应 agent 后重跑。

### 分 Tier 阈值（差异化要求）

| Tier | FPR 上限 | FNR 上限 | 说明 |
|------|----------|----------|------|
| Blocking | 5% | 5% | 安全和数据完整性不容差错 |
| Analytical | 15% | 10% | 架构和模式分析允许适度灰度 |
| Advisory | 25% | 20% | 简洁性和风格建议容忍更高噪声 |

---

## 6. 运行方式：半自动

### 选择理由

| 方式 | 优势 | 劣势 | 适用性 |
|------|------|------|--------|
| 全手动 | 灵活 | 耗时，无法回归 | 不适合 |
| **半自动** | **可回归，人工判定核心指标** | 需要人工标注 TP/FP/FN | **最适合** |
| 全自动 | 快速回归 | 判定 TP/FP 需要 LLM-as-judge，引入二次幻觉 | 远期目标 |

### 执行流程

```
Step 1: 准备 fixture
  └─ 人工编写/从真实 PR 提取 → fixtures/ 目录

Step 2: 运行 agent（半自动）
  └─ 脚本：对每个 case，调用对应 agent + fixture 输入
  └─ 输出存入 results/<case-id>-<timestamp>.md

Step 3: 人工标注（核心步骤）
  └─ 对每个 finding 标注：TP / FP / 遗漏的 FN
  └─ 标注合约合规（字段完整度打分）
  └─ 标注证据质量（可验证性打分）

Step 4: 汇总计算（自动）
  └─ 脚本读取标注结果 → 计算各维度指标 → 生成报告

Step 5: 判定与修复
  └─ 不达标维度 → 修改 agent prompt → 重跑该维度的案例
```

### 运行命令（规划）

```bash
# 运行单个案例
./scripts/run-eval.sh fp-01

# 运行整个维度
./scripts/run-eval.sh --dimension false-positive

# 运行全部案例
./scripts/run-eval.sh --all

# 汇总已标注结果
./scripts/eval-summary.sh
```

> 注：脚本为规划阶段产物，实际实现时再创建。当前阶段用手动方式：
> 1. 将 fixture 内容粘贴给对应 agent
> 2. 收集输出到 results/
> 3. 在 results/ 中手动标注

---

## 7. 与 `/workflows:review` 的集成

### 集成方式：eval 模式标志

在 `/workflows:review` 中增加 `[E]` 标志，进入评测模式：

```bash
# 普通审查
/workflows:review

# 评测模式：用 fixture 替代真实 diff，收集结构化结果
/workflows:review [E] fp-01
```

### 集成点

```
/workflows:review [E] <case-id>
    │
    ├── Phase 0: 解析 [E] 标志
    │   └─ 从 docs/eval/cases/<case-id>.md 读取案例定义
    │   └─ 从 docs/eval/fixtures/<fixture> 读取输入
    │
    ├── Phase 1-3: 正常执行 agent 审查（输入替换为 fixture）
    │
    ├── Phase 4: 评测收集（[E] 模式专属）
    │   └─ 将 agent 输出与案例的 expected_* 字段对比
    │   └─ 生成 results/<case-id>-<timestamp>.md
    │   └─ 标注需人工判定的项
    │
    └── Phase 5: Handoff
        └─ 显示初步评分 + 待人工标注项
        └─ 选项：标注结果 / 运行下一个案例 / 汇总报告
```

### 回归测试用法

agent prompt 修改后，重跑相关维度的案例验证是否改善：

```bash
# 修改 security-sentinel.md 后
/workflows:review [E] fp-01     # 验证误报是否消除
/workflows:review [E] fn-01     # 验证漏报检出率
```

---

## 8. 评测结果存储与可视化

### 存储格式

每次评测结果存入 `docs/eval/results/<case-id>-<YYYYMMDD-HHMM>.md`：

```yaml
---
case_id: fp-01
run_date: "2026-04-07T14:30:00+08:00"
agents_tested:
  - security-sentinel
raw_finding_count: 2
annotations:
  - finding_index: 1
    verdict: FP            # TP | FP | FN
    note: "误将 ENV 引用标记为硬编码"
  - finding_index: 2
    verdict: TP
    note: ""
scores:
  core_judgment: 0.5       # 1 个 FP → 扣分
  contract_compliance: 0.95
  evidence_quality: 0.8
  noise_free: 0.9
  total: 0.74
pass: false
---

## Agent 原始输出

[粘贴完整输出]

## 标注记录

[人工标注详情]
```

### 汇总视图

`docs/eval/results/SUMMARY.md`（由 `eval-summary.sh` 自动生成，每次标注后更新）：

```markdown
# 评测汇总

> 最近更新：2026-04-07

## 维度达标状态

| 维度 | 当前值 | 阈值 | 状态 |
|------|--------|------|------|
| FPR  | 12%    | <=15% | PASS |
| FNR  | 8%     | <=10% | PASS |
| RSR  | 85%    | >=80% | PASS |
| CCR  | 97%    | >=95% | PASS |
| FVR  | 92%    | >=90% | PASS |

## Agent 评分排行

| Agent | 案例数 | 平均分 | 最低分案例 |
|-------|--------|--------|-----------|
| security-sentinel | 4 | 0.82 | fn-01 (0.65) |
| ... | ... | ... | ... |

## 趋势（最近 5 次运行）

| 运行日期 | FPR | FNR | RSR | CCR | 整体 |
|----------|-----|-----|-----|-----|------|
| 2026-04-07 | 12% | 8% | 85% | 97% | PASS |
| ... | ... | ... | ... | ... | ... |
```

### 可视化方式

当前阶段使用 **Markdown 表格**（零依赖，git 可追踪）。

远期可选：
- 将 SUMMARY.md 的数据导出为 JSON → 用 Chart.js 渲染趋势图
- 在 CI 中运行评测 → 将结果作为 PR comment 发布

---

## 附录：快速开始

### 第一次运行评测

1. 创建 fixture 文件（见 `fixtures/` 目录）
2. 选一个 easy 案例：`/workflows:review [E] fp-01`
3. 收集 agent 输出，手动标注 TP/FP/FN
4. 保存到 `results/fp-01-20260407-1430.md`
5. 检查分数是否达标

### 新增案例

1. 在 `cases/` 下创建 `.md` 文件，遵循第 3 节的 Schema
2. 在 `fixtures/` 下创建对应的输入文件
3. 运行并标注
4. 案例积累到 20+ 个后考虑编写自动化脚本
