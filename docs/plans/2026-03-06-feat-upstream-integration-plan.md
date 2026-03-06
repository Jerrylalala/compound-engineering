---
title: "feat: 上游仓库功能整合（方案 C）"
type: feat
date: 2026-03-06
brainstorm: docs/brainstorms/2026-03-05-upstream-integration-strategy-brainstorm.md
sync-report: docs/sync-reports/2026-03-05-upstream-sync.md
---

# feat: 上游仓库功能整合（方案 C — 混合精简版）

## Overview

将 3 个上游仓库（EveryInc、BMAD-METHOD、superpowers）的 10 项高价值功能手工移植到私有 fork。采用 Codex 推荐的方案 C：最小保护层 + 分 2 批上线 + 轻量双命名兼容。

(see brainstorm: docs/brainstorms/2026-03-05-upstream-integration-strategy-brainstorm.md)

## Problem Statement

私有 fork 距上次同步约 1 个月，上游有多项高价值改进未整合：
- EveryInc：workflows:* → ce:* 重命名、plan brainstorm 集成增强、跨平台修复
- BMAD-METHOD：brainstorming no-overwrite、Edge-Case-Hunter、3 个新 skill
- superpowers：SessionStart async 修复、Windows hook 路径修复

## Proposed Solution

**方案 C（Codex 推荐 + 用户确认）**：
- 100% 手工移植（不执行 git merge，无文件删除风险）
- 最小保护层：基线 tag + 冒烟测试（完整 86 文件保护延后到演练轨）
- 分 2 批上线 + 4 项延后
- 双命名仅做 ce:* → workflows:* 轻量转发

## Acceptance Criteria

- [ ] 基线 tag 已打、冒烟测试通过
- [ ] Batch 1（P0）：5 项稳定性修复全部完成
- [ ] Batch 2（P1+P2）：2 项提示词增强 + 3 项 skill 包完成
- [ ] 轻量双命名：ce:* 转发命令创建完成
- [ ] 版本号更新 + CHANGELOG 记录
- [ ] `bash scripts/check-handoff.sh` 全部通过

## Tasks

### Phase 0: 最小保护层

---

### Task 1: 打基线 tag

**操作**:
- [x] 在当前 HEAD 打基线 tag，作为回滚锚点

**代码**:
```bash
git tag baseline-pre-upstream-2026-03 HEAD
```

**验证**:
- [x] 运行 `git tag -l "baseline*"` 确认 tag 存在

---

### Task 2: 创建功能分支

**操作**:
- [x] 从当前分支创建整合分支

**代码**:
```bash
git checkout -b feat/upstream-integration-2026-03
```

**验证**:
- [x] 运行 `git branch --show-current` 确认在 `feat/upstream-integration-2026-03`

---

### Phase 1: Batch 1 — P0 稳定性修复（5 项）

---

### Task 3: SessionStart hook async→false

**文件**: `plugins/compound-engineering/hooks/hooks.json`
**来源**: superpowers (4c83681)
**操作**:
- [x] 将 SessionStart hook 的 `async` 字段从 `true` 改为 `false`

**代码**:
```json
{
  "event": "SessionStart",
  "async": false
}
```

**验证**:
- [x] 确认 hooks.json 中 SessionStart 的 `async` 为 `false`
- [ ] 启动新会话确认 hook 正常加载

---

### Task 4: Windows hook 路径引号修复

**文件**: `plugins/compound-engineering/hooks/session-start.sh`
**来源**: superpowers (31bbbe2)
**操作**:
- [x] 检查 session-start.sh 中所有文件路径是否用双引号包裹
- [x] 修复未引号的路径变量（防止 Windows 路径含空格时出错）（已确认无需修改，路径已正确引号包裹）

**代码**:
```bash
# 修复前（示例）
cat $PLUGIN_DIR/hooks/skill-checking-protocol.md

# 修复后
cat "$PLUGIN_DIR/hooks/skill-checking-protocol.md"
```

**验证**:
- [ ] 在 Windows 11 环境启动新会话，确认无路径错误
- [ ] `grep -n '$' plugins/compound-engineering/hooks/session-start.sh` 检查所有变量引用

---

### Task 5: 跨平台 AskUserQuestion 回退 preamble

**文件**: `plugins/compound-engineering/skills/setup/SKILL.md`
**来源**: EveryInc (9a16de4)
**操作**:
- [x] 在 setup SKILL.md 顶部添加交互方式回退说明
- [x] 在 create-agent-skills 的 create-new-skill.md 和 add-workflow.md 中添加相同 preamble

**代码**（添加到 `## Interaction Method` 之前或替换为）:
```markdown
## Interaction Method

If `AskUserQuestion` is available, use it for all prompts below.

If not, present each question as a numbered list and wait for a reply before proceeding to the next step. For multiSelect questions, accept comma-separated numbers (e.g. `1, 3`). Never skip or auto-configure.
```

**验证**:
- [x] 确认 setup/SKILL.md 包含 `If not, present each question as a numbered list`
- [x] 确认 create-new-skill.md 包含相同 preamble

---

### Task 6: brainstorming no-overwrite 保护

**文件**: `plugins/compound-engineering/commands/workflows/brainstorm.md`
**来源**: BMAD-METHOD (17fe438)
**操作**:
- [x] 在 Phase 3（Capture the Design）中添加已有 brainstorm 检测逻辑
- [x] 检测到同名文件时，提示用户选择续接/新建/查看

**代码**（在 `### Phase 3: Capture the Design` 开头插入）:
```markdown
Before writing, check for existing brainstorm documents with matching topic:

```bash
ls -la docs/brainstorms/*-<topic>-brainstorm.md 2>/dev/null
```

**If a matching brainstorm already exists:**
Use **AskUserQuestion tool** to present options:

**Question:** "发现已有同主题的 brainstorm 文档。如何处理？"

**Options:**
1. **续接** - 在现有文档基础上追加新内容
2. **新建** - 创建新文档（添加日期区分）
3. **查看已有** - 先查看现有内容再决定

Based on selection:
- **续接** → 读取现有文档，在末尾追加新章节
- **新建** → 使用新日期创建独立文档
- **查看已有** → 展示现有文档内容，然后重新呈现选项

**禁止**：检测到存在就自动覆盖或自动续接。
```

**验证**:
- [x] 确认 brainstorm.md 包含 `发现已有同主题的 brainstorm 文档`
- [x] 确认包含 `Based on selection:` 行为约束

---

### Task 7: review.md 渲染修复

**文件**: `plugins/compound-engineering/commands/workflows/review.md`
**来源**: EveryInc (b817b9e)
**操作**:
- [x] 对比上游 ce:review.md 和我们的 review.md，修复格式渲染问题
- [x] 运行 `git show upstream/main:plugins/compound-engineering/commands/ce/review.md` 提取修复内容
- [x] 手工合并格式修复，保留我们的自定义内容（[C][G] 支持、中文化、Based on selection）

**验证**:
- [ ] `bash scripts/check-handoff.sh` 中 review.md 仍为 PASS
- [ ] review.md 中无未闭合的 markdown 格式

---

### Phase 2: Batch 2 — P1 提示词增强 + P2 Skill 包

---

### Task 8: plan.md brainstorm 集成增强（3 条缺失指令）

**文件**: `plugins/compound-engineering/commands/workflows/plan.md:38-44`
**来源**: EveryInc (0e32da2)
**操作**:
- [x] 替换 brainstorm 集成部分（第 38-44 行附近），从 5 点扩展为 7 点

**代码**（替换 `**If a relevant brainstorm exists:**` 下方的列表）:
```markdown
**If a relevant brainstorm exists:**
1. Read the brainstorm document **thoroughly** — every section matters
2. Announce: "Found brainstorm from [date]: [topic]. Using as foundation for planning."
3. Extract and carry forward **ALL** of the following into the plan:
   - Key decisions and their rationale
   - Chosen approach and why alternatives were rejected
   - Constraints and requirements discovered during brainstorming
   - Open questions (flag these for resolution during planning)
   - Success criteria and scope boundaries
   - Any specific technical choices or patterns discussed
4. **Skip the idea refinement questions below** — the brainstorm already answered WHAT to build
5. Use brainstorm content as the **primary input** to research and planning phases
6. **Critical: The brainstorm is the origin document.** Throughout the plan, reference specific decisions with `(see brainstorm: docs/brainstorms/<filename>)` when carrying forward conclusions. Do not paraphrase decisions in a way that loses their original context — link back to the source.
7. **Do not omit brainstorm content** — if the brainstorm discussed it, the plan must address it (even if briefly). Scan each brainstorm section before finalizing the plan to verify nothing was dropped.
```

**验证**:
- [x] 确认 plan.md 包含 `Critical: The brainstorm is the origin document`
- [x] 确认 plan.md 包含 `Do not omit brainstorm content`
- [x] 确认共 7 个编号条目
- [ ] `bash scripts/check-handoff.sh` 中 plan.md 仍为 PASS

---

### Task 9: Edge-Case-Hunter 审查步骤

**文件**: `plugins/compound-engineering/commands/workflows/review.md`
**来源**: BMAD-METHOD (43cfc01)
**操作**:
- [x] 在 review.md 的审查阶段中添加 Edge-Case-Hunter 可选步骤
- [x] 提取 BMAD 的核心 prompt 模式，中文化后嵌入

**代码**（在 review.md 的代码审查阶段后添加）:
```markdown
### 可选：边缘案例狩猎

如果审查范围涉及用户输入处理、状态管理或并发逻辑，执行边缘案例分析：

1. **识别输入边界**：空值、极端值、非法格式、Unicode 特殊字符
2. **状态转换**：是否有未覆盖的状态组合？中间状态是否安全？
3. **并发场景**：多用户/多会话同时操作是否安全？
4. **失败路径**：网络断开、文件锁定、权限不足时的行为

将发现的边缘案例添加到审查报告的"风险"部分。
```

**验证**:
- [x] 确认 review.md 包含 `边缘案例狩猎`
- [ ] `bash scripts/check-handoff.sh` 仍全部 PASS

---

### Task 10: 移植 Findings-Triage skill

**目标目录**: `plugins/compound-engineering/skills-custom/findings-triage/`
**来源**: BMAD-METHOD (7ece8b0)
**操作**:
- [x] 创建 `skills-custom/findings-triage/SKILL.md`
- [x] 从 BMAD 源提取核心 triage 流程，中文化
- [x] 按 Skill Compliance Checklist 验证 frontmatter

**代码**:
```markdown
---
name: findings-triage
description: This skill should be used when review findings need structured prioritization. It categorizes findings by severity (P0-P3) and provides actionable resolution guidance.
---

# 发现分类技能

## 触发条件

当代码审查、安全扫描或测试报告产生多个发现需要优先级排序时使用。

## 分类标准

| 级别 | 标准 | 响应 |
|------|------|------|
| **P0** | 阻断发布、数据丢失、安全漏洞 | 立即修复 |
| **P1** | 功能缺陷、用户可见 bug | 本轮修复 |
| **P2** | 代码质量、可维护性 | 下轮修复 |
| **P3** | 优化建议、样式偏好 | 记录备忘 |

## 执行流程

1. 收集所有发现（审查报告、测试输出、lint 结果）
2. 按上表分类每个发现
3. 对 P0/P1 生成修复任务（含文件路径和预期修改）
4. 对 P2/P3 记录到 backlog
5. 输出结构化报告

## 输出格式

```markdown
## Triage 报告

### P0 — 立即修复
- [ ] [发现描述] → [文件:行号] → [修复方案]

### P1 — 本轮修复
- [ ] [发现描述] → [文件:行号] → [修复方案]

### P2 — 下轮修复
- [发现描述]

### P3 — 记录备忘
- [发现描述]
```
```

**验证**:
- [x] 文件存在于 `skills-custom/findings-triage/SKILL.md`
- [x] frontmatter `name` 为 `findings-triage`
- [x] `description` 使用第三人称（`This skill should be used when...`）

---

### Task 11: 移植 Review-Prompt skill

**目标目录**: `plugins/compound-engineering/skills-custom/review-prompt/`
**来源**: BMAD-METHOD (9536e1e)
**操作**:
- [x] 创建 `skills-custom/review-prompt/SKILL.md`
- [x] 从 BMAD 源提取 prompt 自审流程，中文化

**代码**:
```markdown
---
name: review-prompt
description: This skill should be used when reviewing or improving AI prompt files (.md command/skill definitions). It evaluates clarity, completeness, and effectiveness of prompt instructions.
---

# 提示词审查技能

## 触发条件

当需要审查或改进 AI 提示词文件（commands/*.md、skills/*/SKILL.md）时使用。

## 审查维度

1. **清晰度**：指令是否明确无歧义？AI 能否只按一种方式理解？
2. **完整性**：是否覆盖所有场景（成功、失败、边缘情况）？
3. **一致性**：术语、格式、语气是否前后一致？
4. **可测试性**：是否有可验证的输出标准？
5. **简洁性**：是否有冗余指令？能否精简而不损失信息？

## 执行流程

1. 读取目标提示词文件
2. 按 5 个维度逐一评分（1-5 分）
3. 对低分项生成具体改进建议（含改写示例）
4. 输出审查报告
```

**验证**:
- [x] 文件存在于 `skills-custom/review-prompt/SKILL.md`
- [x] frontmatter 合规

---

### Task 12: 移植 Root cause analysis skill

**目标目录**: `plugins/compound-engineering/skills-custom/root-cause-analysis/`
**来源**: BMAD-METHOD (2f484f1)
**操作**:
- [x] 创建 `skills-custom/root-cause-analysis/SKILL.md`
- [x] 从 BMAD 源提取根因分析流程，中文化
- [x] 确认与现有 `systematic-debugging` 技能互补（非重复）

**代码**:
```markdown
---
name: root-cause-analysis
description: This skill should be used when a bug's surface symptoms have been identified but the underlying cause remains unclear. It complements systematic-debugging by focusing specifically on causal chain analysis.
---

# 根因分析技能

## 与 systematic-debugging 的关系

- `systematic-debugging`：从症状出发，系统排查定位问题
- `root-cause-analysis`：问题已定位后，深挖根因防止复发

## 5-Why 分析法

对已知问题连续追问"为什么"，直到触及根本原因：

```
症状：用户会话数据丢失
→ 为什么？SessionStart hook 未执行
→ 为什么？hook async=true 导致竞态
→ 为什么？默认配置未考虑慢速环境
→ 为什么？缺少跨平台测试覆盖
→ 根因：hook 执行模型假设了快速同步环境
```

## 执行流程

1. **症状确认**：复现问题，记录准确症状
2. **直接原因**：定位触发问题的代码/配置
3. **5-Why 链**：连续追问至根因（通常 3-5 层）
4. **验证根因**：修改根因后确认症状消失
5. **防复发**：提出结构性修复（非只修表面）

## 输出格式

```markdown
## 根因分析报告

**症状**: [用户可见的问题]
**直接原因**: [触发问题的代码/配置]
**根因链**:
1. [第一层 why]
2. [第二层 why]
3. [根因]

**修复方案**: [结构性修复]
**防复发措施**: [测试/监控/约束]
```
```

**验证**:
- [x] 文件存在于 `skills-custom/root-cause-analysis/SKILL.md`
- [x] description 明确提到 `complements systematic-debugging`

---

### Phase 3: 轻量双命名兼容

---

### Task 13: 创建 ce:* 转发命令

**目标目录**: `plugins/compound-engineering/commands/ce/`
**操作**:
- [x] 为 9 个 workflows 命令创建对应的 ce:* 转发文件
- [x] 每个转发文件使用 `disable-model-invocation: true`
- [x] 转发文件内容简洁，直接 forward 到 workflows:*

**代码**（以 ce/plan.md 为例，其余同理）:

`commands/ce/plan.md`:
```markdown
---
name: ce:plan
description: "Alias for /workflows:plan — 将功能描述转化为结构清晰的项目计划"
argument-hint: "[feature description or brainstorm path]"
disable-model-invocation: true
---

/workflows:plan $ARGUMENTS
```

需创建的转发文件列表：
| ce:* 命令 | 转发到 |
|-----------|--------|
| ce/brainstorm.md | /workflows:brainstorm |
| ce/plan.md | /workflows:plan |
| ce/work.md | /workflows:work |
| ce/review.md | /workflows:review |
| ce/compound.md | /workflows:compound |
| ce/load.md | /workflows:load |
| ce/save.md | /workflows:save |
| ce/sync-upstream.md | /workflows:sync-upstream |
| ce/doctor.md | /workflows:doctor |

**验证**:
- [x] `ls plugins/compound-engineering/commands/ce/` 确认 9 个文件存在
- [x] 每个文件包含 `disable-model-invocation: true`
- [x] 每个文件最后一行为 `/workflows:* $ARGUMENTS` 格式

---

### Phase 4: 收尾

---

### Task 14: 更新 CLAUDE.md 双命名说明

**文件**: `plugins/compound-engineering/CLAUDE.md`
**操作**:
- [x] 在 Workflow 命令列表后添加双命名说明

**代码**（在命令列表表格后追加）:
```markdown
### 双命名兼容

所有 `workflows:*` 命令均有对应的 `ce:*` 别名（与上游 EveryInc 保持术语兼容）：

```
/ce:plan        → /workflows:plan
/ce:brainstorm  → /workflows:brainstorm
/ce:work        → /workflows:work
/ce:review      → /workflows:review
/ce:compound    → /workflows:compound
...（其余同理）
```

**本仓库以 `workflows:*` 为主命令**，`ce:*` 仅为转发别名。
```

**验证**:
- [x] CLAUDE.md 包含 `双命名兼容` 章节
- [x] 明确标注 `workflows:*` 为主命令

---

### Task 15: 版本号更新 + CHANGELOG

**文件**: `.claude-plugin/marketplace.json`, `plugins/compound-engineering/.claude-plugin/plugin.json`, `plugins/compound-engineering/CHANGELOG.md`
**操作**:
- [x] 使用 bump-version 脚本更新版本号（minor bump）
- [x] 在 CHANGELOG.md 添加版本记录

**代码**:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -BumpType minor
```

CHANGELOG 条目：
```markdown
## [v2.43.0] - 2026-03-06

### Added
- 跨平台 AskUserQuestion 回退 preamble（EveryInc #204 移植）
- brainstorming no-overwrite 保护（BMAD-METHOD 移植）
- Edge-Case-Hunter 审查步骤（BMAD-METHOD 移植）
- 3 个新 skill：findings-triage、review-prompt、root-cause-analysis（BMAD-METHOD 移植）
- ce:* 转发命令（9 个，轻量双命名兼容）
- plan.md brainstorm 集成增强（7 点指令，EveryInc 移植）

### Fixed
- SessionStart hook async 竞态条件（superpowers 移植）
- Windows hook 路径引号问题（superpowers 移植）
- review.md 格式渲染问题（EveryInc 移植）

### Changed
- CLAUDE.md 添加双命名兼容说明
```

**验证**:
- [x] `powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1` 通过
- [x] CHANGELOG.md 包含 v2.43.0 条目

---

### Task 16: 更新组件统计

**文件**: `CLAUDE.md`, `.claude-plugin/marketplace.json`, `plugins/compound-engineering/.claude-plugin/plugin.json`
**操作**:
- [x] 统计最新组件数量并更新

**代码**:
```powershell
# 统计
(Get-ChildItem -Recurse plugins/compound-engineering/agents/*.md).Count    # Agents
(Get-ChildItem -Recurse plugins/compound-engineering/commands/*.md).Count   # Commands（含新增 ce/ 目录）
(Get-ChildItem -Directory plugins/compound-engineering/skills/).Count       # Skills
```

**验证**:
- [x] CLAUDE.md 中组件数量与实际一致
- [x] marketplace.json 和 plugin.json 中的数量一致

---

### Task 17: 最终冒烟测试

**操作**:
- [x] 运行 Handoff lint 检查
- [x] 运行版本一致性检查
- [x] 验证新增 skill 文件合规性

**代码**:
```bash
# Handoff 完整性
bash scripts/check-handoff.sh

# 版本一致性
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1

# Skill frontmatter 检查
grep -E '^description:' plugins/compound-engineering/skills-custom/*/SKILL.md | grep -v 'This skill'
# 应返回空（所有 description 使用第三人称）
```

**验证**:
- [x] check-handoff.sh 全部 PASS
- [x] check-versions.ps1 版本一致
- [x] skill frontmatter 检查无输出

---

## 延后项（P3 — 单独计划）

以下项目不纳入本次计划，需单独立项：

| 项目 | 来源 | 延后理由 |
|------|------|----------|
| Cursor 支持 | superpowers | 需要 .cursor-plugin/ 目录 + 双格式 hook，外部依赖重 |
| Proof 协作文档 | EveryInc | 依赖 Proof Web API，需评估可用性 |
| 内部全面切 ce:* | EveryInc | 与 14 项移植耦合风险高，单独计划 |
| 86 文件完整保护层 | brainstorm | 给演练轨 dry-run merge 用，非本轮必需 |
| Quick-Dev2 统一工作流 | BMAD-METHOD | 与现有结构冲突大 |
| 强制 brainstorming | superpowers | 理念已通过 Handoff 协议覆盖 |
| 多 IDE 同步基础设施 | EveryInc | CLI 层面，不涉及提示词 |
| Qwen Code 支持 | EveryInc | 仅参考转换逻辑 |

## References

- Brainstorm: `docs/brainstorms/2026-03-05-upstream-integration-strategy-brainstorm.md`
- Sync Report: `docs/sync-reports/2026-03-05-upstream-sync.md`
- Codex 咨询结论：方案 C（混合精简版）
- 上游 ce:plan brainstorm 指令差异：EveryInc commit 0e32da2
- 跨平台 preamble 模式：EveryInc commit 9a16de4
- BMAD skills 参考：commits 7ece8b0、9536e1e、2f484f1
