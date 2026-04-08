---
run_date: "2026-04-08"
review_type: "harness-fusion-comprehensive"
agents_used: 9
scope: "Harness Fusion P0-P8 全实现审核"
p1_count: 6
p2_count: 11
p3_count: 8
codex_status: "last-commit scope, 结果待追加"
---

# Harness Fusion P0-P8 综合代码审核

**审核日期**: 2026-04-08  
**审核范围**: Harness Fusion Phase 0-4 全部实现（P0-P8 协议）  
**代理数量**: 9 个并行审核代理（architecture, security, eval, review-contract, fsm/task-bundle, executor, compound/intent, simplicity, scripts）  
**Codex `[C]`**: last-commit 范围（branch scope 无 diff，已在 main）

---

## 🔴 P1 — Critical（6 条，阻断正常使用）

### P1-1: `codex --dry-run` 参数未经验证

**文件**: `plugins/compound-engineering/skills-custom/patch-approval/SKILL.md:31`

**问题**: 
```bash
codex --dry-run "$TASK_PROMPT" > /tmp/codex-patch.diff
```
整个 Patch Approval 安全审批层依赖 Codex CLI 的 `--dry-run` 参数，但此参数在官方文档中从未被确认存在。SKILL.md 第 103 行自身也承认"需要 Codex CLI 支持 `--dry-run` 参数"。若参数不存在，Codex 会直接执行写入而非生成 patch，审批层完全失效。

**修复建议**: 
1. 运行 `codex --help | grep dry-run` 验证参数
2. 若不存在，改为"Codex 在隔离目录执行 + git diff 捕获"方案
3. 在 executor-capability-gate 增加 Check 6：验证 `--dry-run` 支持

---

### P1-2: executor-capability-gate Check 2 登录检测逻辑错误

**文件**: `plugins/compound-engineering/skills-custom/executor-capability-gate/SKILL.md:36-38`

**问题**: 
```bash
codex --version 2>&1 | grep -q "version" && echo "OK" || echo "NOT_LOGGED_IN"
```
`codex --version` 不需要登录即可执行，此检查永远返回 OK。

**修复建议**: 替换为凭据文件检查 `[ -f ~/.codex/auth.json ]` 或合并到 Check 3 的 HTTP 401 检测。

---

### P1-3: `~/.codex/.last_call` 从未写入，Check 4 Rate Limit 检查失效

**文件**: `executor-capability-gate/SKILL.md:68-75`（读取逻辑存在，但无任何写入逻辑）

**问题**: Rate Limit 检查依赖 `~/.codex/.last_call` 文件，但全仓库（executor-capability-gate、codex-first-executor、patch-approval）均无写入此文件的代码。`LAST_CALL` 永远为 "0"，检查永远通过。

**修复建议**: 在 codex-first-executor 成功调用 Codex 后追加 `date +%s > ~/.codex/.last_call`。

---

### P1-4: ce-work-integration 跳过 FSM `resumed` 状态

**文件**: `plugins/compound-engineering/skills-custom/ce-work-integration/SKILL.md:61` vs `docs/specs/failure-fsm.md:86-87`

**问题**: 
- ce-work-integration："replanned → active: 按新计划重新开始（标记为 resumed）"
- failure-fsm.md："replanned → resumed（用户确认）→ resumed → active（AI）"

ce-work-integration 跳过了需要用户确认的 `resumed` 中间状态，直接从 `replanned` 转入 `active`，违反 FSM 安全门控设计。

**修复建议**: 在 ce-work-integration 中拆分为两步，增加用户确认门。

---

### P1-5: `bump-version.ps1` 损坏

**文件**: `scripts/bump-version.ps1:77,86`

**问题**: 
```powershell
$marketplace.plugins[0].version = $newVersion  # plugins[0] 无此字段
```
上游合并后 marketplace.json 的 plugins 数组中已删除 version 字段（只有 `metadata.version`）。运行脚本会在 plugins[0] 中注入新的 version 字段，污染 marketplace.json 结构。`check-versions.ps1` 也有同样问题，会产生假报告。

**修复建议**: 
- 删除 bump-version.ps1 第 75-80 行（marketplace.json 更新代码）
- 修改验证逻辑只检查 plugin.json
- CLAUDE.md 文档中版本来源说明需更新

---

### P1-6: Review Contract 6 个 Agent 名称与上游 persona-catalog 不匹配

**文件**: `plugins/compound-engineering/skills-custom/review-contract/SKILL.md`，对照 `skills/ce-review/references/persona-catalog.md`

**不匹配的名称**:
| Review Contract 中 | 上游实际名称 |
|-------------------|------------|
| `data-integrity-guardian` | 不存在 |
| `data-migration-expert` | `data-migrations-reviewer` |
| `architecture-strategist` | 不存在（仅存在于 skills-custom） |
| `performance-oracle` | `performance-reviewer` |
| `pattern-recognition-specialist` | 不存在（仅存在于 skills-custom） |
| `code-simplicity-reviewer` | 不存在 |

**影响**: Tier 分类无法绑定到真实执行的上游 agent。

**修复建议**: 对齐名称，并在文档中明确区分"本地自定义 skill"与"上游 persona"。

---

## 🟡 P2 — Important（11 条）

### P2-1: 所有 Overlay 无强制激活入口

**问题**: 上游 `commands/` 目录中对 `skills-custom/` 的引用为零。所有协议链（Intent Gate、Review Contract、Executor Capability Gate 等）依赖 AI 自觉加载，实践中极易被跳过。

**修复建议**: 在 `ce-work/SKILL.md` 和 `ce-review/SKILL.md` 中显式引用关键 Overlay，或创建编排入口 Skill。

---

### P2-2: `conclusion_type` 字段不被上游 merge pipeline 消费

**文件**: `review-contract/SKILL.md:24-33`，上游 `findings-schema.json`

**问题**: `conclusion_type`（finding/question/needs-human-check/clear）是 overlay 的"虚字段"，上游 Stage 5 merge 管道只处理 `autofix_class/owner/requires_verification/confidence`，不读取 `conclusion_type`。

**修复建议**: 明确 `conclusion_type` 的消费者，或在文档中标注为"仅供人类阅读，不影响 merge 管道路由"。

---

### P2-3: task-bundle/SKILL.md 说"未集成"但 ce-work-integration 已完整实现

**文件**: `task-bundle/SKILL.md:36-43`

**问题**: "Phase 0 说明：当前 Task Bundle 是独立的文档协议，不与 workflow 命令自动集成" —— 但 `ce-work-integration` 已经在 Phase 0/1/4 中实现了完整的 state.md 读写和 FSM 集成。文档说"未实现"导致功能永远不被激活。

**修复建议**: 更新 task-bundle/SKILL.md 的 Phase 0 说明，反映集成已通过 ce-work-integration overlay 实现，并链接到该 skill。

---

### P2-4: Compound Promotion Ladder 未与 ce:compound 集成

**问题**: SKILL.md 声称"ce:compound 完成后自动运行 Promotion 检测"，但 `ce-compound/SKILL.md` 整个流程中没有对 compound-promotion-ladder 的任何引用。

**修复建议**: 在 `ce-compound/SKILL.md` Phase 2 后加入 Phase 3（Promotion 检测调用）。

---

### P2-5: Intent Gate 未与 ce:work Phase 0 集成

**问题**: 同上，`ce-work/SKILL.md` 的 Phase 0 只有"Input Triage"，未集成意图分类。

**修复建议**: 在 `ce-work/SKILL.md` Phase 0 中融合 Intent Gate 流程。

---

### P2-6: Anti-leniency system_prompt_suffix 注入机制无实现点

**文件**: `review-contract/SKILL.md:39`

**问题**: 声称注入方式为 `system_prompt_suffix`，但上游 ce:review Stage 4 的 subagent 派发模板无此扩展点。注入机制仅停留在意图层面。

**修复建议**: 在文档中标注为"未实现——依赖未来上游支持"，避免误导。

---

### P2-7: Compound Promotion Ladder bash 脚本中变量未定义（死代码）

**文件**: `compound-promotion-ladder/SKILL.md:33-44`

**问题**: 
```bash
SIMILAR_COUNT=$(grep -rl "tags:.*$TAG" docs/solutions/ | wc -l)
```
`$TAG` 和 `$RELATED_FILE` 在整个 SKILL.md 中无定义，自动检测脚本永远产出错误结果。

**修复建议**: 替换为自然语言描述，删除约 20 行伪代码。

---

### P2-8: Advisory Tier 规则 3 与 AL-D eval 案例矛盾

**文件**: `review-contract/SKILL.md:74` vs `docs/eval/cases/al-d-opinion-vs-finding.md`

**问题**: 规则 3 说"不要因为「代码可以更好」就报 finding，放入 residual_risks 更合适"，但 AL-D 案例期望"保留 `conclusion_type: finding`（降级 severity）"。两者行为定义相互矛盾。

**修复建议**: 明确区分两类：有事实依据可量化的品味问题 → 保留 finding 但降级；纯主观判断 → 放入 residual_risks。

---

### P2-9: Phase 编号冲突

**文件**: `ce-work-integration/SKILL.md:24` vs `ce-work/SKILL.md:21`

**问题**: ce-work-integration 的"Phase 0: 任务恢复"与上游 ce:work 的"Phase 0: Input Triage"命名冲突，intent-gate 的"Phase 0.5"进一步增加混淆。

**修复建议**: Overlay 中的 Phase 统一改为带前缀的标识符，如 `[OVERLAY-RECOVERY]`。

---

### P2-10: state.md.tpl 缺少 2 个字段

**文件**: `task-bundle/templates/state.md.tpl`

**缺失字段**:
```yaml
snapshot_retention: 5      # Windows 兼容，保留最近 N 个快照
context_hash: null         # 检测漂移的 SHA256 哈希
```

**修复建议**: 在 state.md.tpl 中补充这两个字段。

---

### P2-11: Eval Set 三份文档阈值不一致 + al-a~al-d frontmatter 格式不符合规范

**文件**: `docs/eval/EVAL-DESIGN.md`, `SCORING.md`, `scoreboard.md`，`cases/al-*.md`

**问题**:
1. 三份文档中 FPR/FNR/CCR 阈值定义不完全一致
2. Anti-leniency 4 个案例使用 `eval_id` 而非 `id`，缺少 `name`、`fixture`、`scoring` 等标准字段
3. SCORING.md 缺少 RSR 和 FVR 的具体计算公式

**修复建议**: 统一阈值定义源（推荐 EVAL-DESIGN.md），补充 AL 案例的标准字段。

---

## 🔵 P3 — Nice-to-Have（8 条）

| # | 问题 | 文件 | 建议 |
|---|------|------|------|
| P3-1 | executor-capability-gate Check 5 与 codex-first-executor 路由矩阵重复（12 行） | executor-capability-gate/SKILL.md:79-89 | Check 5 改为一行引用 |
| P3-2 | executor-capability-gate 缓存机制 `stat -c %Y` Linux-only + YAGNI | executor-capability-gate/SKILL.md:138-153 | 删除整个缓存节（16 行） |
| P3-3 | compound-promotion-ladder bash 脚本死代码 | compound-promotion-ladder/SKILL.md:36-43, 81-91 | 删除约 20 行，替换为自然语言 |
| P3-4 | review-contract "遗留问题"节不属于运行时 prompt | review-contract/SKILL.md:108-113 | 删除整节（6 行），移入 CLAUDE.md |
| P3-5 | codex-first-executor Gemini 暂缓节 11 行零信息密度 | codex-first-executor/SKILL.md:85-95 | 删除整节，frontmatter 加一句 |
| P3-6 | ui-review-contract `$PLAN_FILE` 变量来源未定义 | ui-review-contract/SKILL.md:108-119 | 补充变量来源说明 |
| P3-7 | `nul` 文件（PowerShell 副产品）需清理 | 根目录 `nul` | `rm nul` |
| P3-8 | docs/sync-reports/ 三个报告文件未提交 | docs/sync-reports/ | 提交作为审计记录 |

---

## Codex 审核（已完成）

**审核范围**: last-commit（ae67a19 feat(harness-fusion): Phase 1-4）  
**模型**: gpt-5.4（via Codex cloud backend）  
**完成时间**: 2026-04-08  
**Token 消耗**: input 5,090,438 / output 16,661

### Codex 发现（5 条，补充 Claude 9-agent 审核）

#### 🔴 Codex-C1: 版本链路漂移（上游合并副作用）

**证据**:
- `plugins/compound-engineering/.claude-plugin/plugin.json:3` → `"version": "2.45.2"`（私有版本）
- `plugins/compound-engineering/.cursor-plugin/plugin.json:4` → `"version": "2.63.1"`（上游版本，随合并带入）
- `package.json:3` → `"version": "2.63.1"`（上游版本）
- `.github/.release-please-manifest.json:3` → `2.63.1`（上游版本）

**影响**: 上游合并后 cursor-plugin/package.json 版本（2.63.1）与私有 claude-plugin 版本（2.45.2）不一致，CI release:validate 未覆盖此检查。

**修复建议**: 统一决策：要么将 cursor-plugin/package.json 回落到 2.45.2，要么说明这是"私有 claude 版本 vs 上游 cursor 版本"的预期差异，并在 CLAUDE.md 中说明。

---

#### 🔴 Codex-C2: `deploy-docs.yml` 指向不存在的目录

**文件**: `.github/workflows/deploy-docs.yml:7,35`

**问题**:
```yaml
paths: ['plugins/compound-engineering/docs/**']  # 不存在
path: 'plugins/compound-engineering/docs'         # 不存在
```
实际文档在根目录 `docs/`，该 workflow 永远不会被触发，artifact 路径也会失效。

**修复建议**: 改为 `docs/**` 和 `docs`，与实际文档目录对齐。

---

#### 🟡 Codex-W1: `release-preview.yml` Shell 注入风险

**文件**: `.github/workflows/release-preview.yml:83-84`

**问题**:
```yaml
TITLE='${{ steps.inputs.outputs.title }}'
FILES='${{ steps.inputs.outputs.files }}'
```
commit title 或文件名含单引号会破坏脚本，且可被构造为命令注入。

**修复建议**: 通过 `env:` 传值，在 bash 中安全读取：
```yaml
env:
  TITLE: ${{ steps.inputs.outputs.title }}
  FILES: ${{ steps.inputs.outputs.files }}
```

---

#### 🟡 Codex-W2: `triage-prs` 命令 frontmatter 与正文不一致

**文件**: `.claude/commands/triage-prs.md:5-6,57,120`

**问题**:
- `disable-model-invocation: true`，只允许 `Bash(gh *)` 和 `Bash(git log *)`
- 正文需要 `Task`/`AskUserQuestion`（第 57、120 行）和 `git branch`（第 17 行）

命令大概率无法执行。

**修复建议**: 对齐 frontmatter，开放实际需要的工具；或重写正文去掉不支持的工具调用。

---

#### 🔵 Codex-I1: `deploy-docs` skill 文档路径旧引用

**文件**: `plugins/compound-engineering/skills/deploy-docs/SKILL.md:26,37,69,92`

仍引用 `plugins/compound-engineering/docs`（不存在路径），与 Codex-C2 同根。建议随 workflow 一起修复。

---

## 后续行动优先级

### 已完成 ✅
- [x] `scripts/bump-version.ps1` — 删除 marketplace 更新逻辑（已修复并合并）
- [x] `scripts/check-versions.ps1` — 修复版本比较逻辑（已修复并合并）
- [x] 提交 `docs/eval/` 全部文件（RUNBOOK/SCORING/cases/fixtures/results）
- [x] 提交 `docs/sync-reports/` + 删除 nul 文件
- [x] Codex 审核结果已追加（Codex-C1/C2/W1/W2/I1）

### 立即（P1 修复，未完成）
1. **Codex-C2** + **Codex-I1**: `.github/workflows/deploy-docs.yml` 路径错误 → 改为 `docs/`
2. **P1-4**: `skills-custom/ce-work-integration/SKILL.md` — 补充 `resumed` 中间状态
3. **P1-1**: `skills-custom/patch-approval/SKILL.md` — 标注 `--dry-run` 前提条件为未验证
4. **P1-2/3**: `skills-custom/executor-capability-gate/SKILL.md` — Check 2 登录检测 + Check 4 写入逻辑
5. **P1-6**: `skills-custom/review-contract/SKILL.md` — 对齐 6 个 agent 名称
6. **Codex-C1**: 决策版本策略（cursor-plugin 2.63.1 vs claude-plugin 2.45.2）

### 本周（P2 核心修复）
7. **Codex-W2**: `triage-prs.md` frontmatter 对齐
8. **Codex-W1**: `release-preview.yml` 参数注入修复
9. 在 ce-work/ce-review/ce-compound 中添加 Overlay 触发入口
10. 更新 task-bundle/SKILL.md 说明集成现状
11. 修复 Advisory Tier 规则 3 与 AL-D 矛盾
12. 补充 state.md.tpl 缺失字段
13. 统一 Eval 三份文档的阈值

### 可选（P3 简化）
14. 删除约 93 行冗余内容（见 P3 列表）
