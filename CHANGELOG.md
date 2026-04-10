# Changelog

## [2.46.3] - 2026-04-10

### 文档 + UX 改进

- **命令步骤编号**：5 个工作流命令 description 加入 "Step X/5" 前缀，autocomplete 列表直接显示操作顺序（brainstorm=1, plan=2, work=3, review=4, compound=5）
- **README 竞品对比重写**：新增「Agent / 能力覆盖对比」矩阵（CE / CE-UP / SP / OMCC / CCG），新增「关键特性横向对比」表，加入 Superpowers（SP）、OMCC、CCG，公平评价各项目强项与局限，附「如何选择」决策指南

---

## [2.46.2] - 2026-04-10

### 文档 + 准确性修复

- **[ce:brainstorm] 命令**：删除 `[team]` 参数标记（该参数已于 `ca86a3c` 有意从 SKILL.md 移除，探索者+挑战者收敛已内置为 `[P]` 的自动行为；`ac9f2b4` 为修复自动补全意外将其加回 description，造成误导）。保留 `[P][C][G][R]` 实际支持的参数，`[P]` 的 argument-hint 明确标注包含自动收敛
- **README**：新增「与同类项目对比」章节，包含 EveryInc 上游、awesome-claude-code、claude-octopus 等 5 个项目的横向对比，以及本项目 vs 上游的功能差异矩阵
- **交互式工作流可视化**：新增 `docs/zh-CN/workflow.html` 单页交互应用，点击每个工作流阶段展示参数说明（区分真实实现/可选增强）和使用示例；MkDocs 导航新增「交互式工作流」入口
- **版本号**：2.46.1 → 2.46.2

---

## [2.46.1] - 2026-04-10

### Bug 修复：P0/P1 一致性修复

- **[team-mode] SKILL.md**：删除 `ce:brainstorm [team:full]` 行（该行暗示 brainstorm 支持 [team:full]，与设计矛盾）
- **[team-mode] SKILL.md**：修正 overlay 声明，明确 `ce:brainstorm` 不在 [team] 覆盖范围内
- **[team-mode] SKILL.md**：修正 verifier/risk-guard 的"持续等待"措辞 → "等待激活，每次收到消息执行一次，完成后等待下一次"（one-shot 语义，非 daemon）
- **[ce:brainstorm] SKILL.md**：将 [P] 收敛执行逻辑从 Parameter Handling 移至 Execution Flow Phase 0.5（有明确挂载点，执行时机清晰）
- **[ce:work] SKILL.md**：在 Phase 4 Step 5 添加 `TeamDelete(TEAM_NAME)` 销毁步骤（此前仅 team-mode 提及，ce:work 本体遗漏）

---

## [2.46.0] - 2026-04-10

### 新功能：[team] 升级为 Claude Code 原生 Agent Teams

**核心变更**：`ce:work [team]` 从角色模拟升级为真实 Claude Code Agent Teams。

旧机制：同一 agent 顺序扮演 合约主/执行者/验证者，文件 I/O 通信（角色模拟）
新机制：`TeamCreate` 创建命名团队，spawn 独立 context window 的 verifier/risk-guard teammate，`SendMessage` 实时通信，`TeamDelete` 收尾

**变更文件（2个核心文件 + CLAUDE.md）**：

- **[team-mode] SKILL.md 大改**：ce:work [team] 节完整重写为真实 Agent Teams 流程
  - Phase -1：TeamCreate + spawn verifier（只读，独立 context window）+ [team:full] 额外 spawn risk-guard
  - Phase 2：每 Unit 完成后 SendMessage("verifier", ...) → 等 PASS/FAIL → 修复或继续
  - 全量集成验证：所有 Unit 完成后 verifier 额外运行一次
  - Phase 4：TeamDelete 清理
  - 固定消息协议（4 种消息格式）
  - 降级策略（Agent Teams 不可用时自动降级为主 agent 顺序验证）
  - 角色定义表格同步更新（合约主/验证者/风险卫描述与新机制对齐）
  - `.team-contract.md` 定位改为"团队章程"（所有 teammate 启动时读取）

- **[ce:work] SKILL.md 中改**：Phase -1 [team] 检测说明更新为完整 Agent Teams 流程摘要；Phase 1 team mode dispatch 更新为 SendMessage 协议

- **[CLAUDE.md] 小改**：Agent Teams 集成章节重写，[team] 参数说明更新为真实 Agent Teams 语义

**Codex 交叉验证（2026-04-10）纳入的 4 个关键约束**：
1. verifier 只读约束（严禁修改任何文件，含 .team-contract.md）
2. 固定消息协议（unit_id / files / 修复说明 / 全量验证）
3. 超时降级（60s 无回复 → 主 agent 直接验证）
4. 全量集成验证（所有 Unit 完成后额外一次）

### 修复（链路审查 5 个 bug）

- **[team-mode] Bug 1 修复**：头部"核心理念"「不来自更多 agent」与 ce:work 新设计矛盾，改为分层说明（ce:work=真实 Agent Teams，brainstorm/plan/review=有意设计的角色模拟/规则引擎）
- **[team-mode] Bug 2 修复**："参数变体"表格更新，明确 ce:work 使用真实 teammate，brainstorm/plan/review 保留角色模拟
- **[team-mode] Bug 3 修复**：TEAM_NAME 时间戳粒度从小时级改为秒级（`YYYYMMDDTHHmmss`），防止同小时内重复运行碰撞
- **[ce-work] Bug 4 修复**：并行 subagent 场景新增传递 TEAM_NAME 的明确指令，确保 subagent 能正确调用 SendMessage 找到 verifier
- **[team-mode] Bug 5 修复**：brainstorm/plan/review 节各增加实现层次说明注释，明确标注"有意设计，非遗漏"

## [2.45.23] - 2026-04-09

### 修复（第三方审核 + 事实核查：5 个确认问题）
- **[ce:review] P1 修复**: 6.5b 标题「仅当 mode == autofix」与参数表（interactive+autofix 均生效）和伪代码矛盾，已统一为「autofix 和 interactive 均生效，report-only/headless 跳过」
- **[ce:work] P2 修复**: [R] 标志未在 Phase -1 剥离，若传 `plan.md [R]` 会导致路径解析污染；现在 Phase -1 最先检测并剥离 [R]，设置 R_MODE_ENABLED
- **[ce:work] P2 修复**: Phase 0 [R] 检索触发条件从 `$ARGUMENTS 包含 [R]` 改为 `R_MODE_ENABLED = true`（与 Phase -1 设置的变量保持一致）
- **[ce:work] P2 修复**: Handoff 选 2「调用 `workflows:pr` skill」改为「执行 `/workflows:pr` command」（workflows:pr 是 Command 不是 Skill）
- **[ce:work] P2 修复**: 移除 `imgup` skill 引用（插件中不存在该组件）；移除 `linting-agent` 引用（不存在），改为通用 lint 命令说明
- **[ce:plan] P2 修复**: Phase 4.5 合约生成时机描述更新：从「Phase 5.3（Handoff）之前」改为「Phase 5.3（Deepening）完成后，5.3.8 之前」，防止 Deepening 新增文件后合约过期

## [2.45.22] - 2026-04-09

### 修复（全量链路审查：2 个 P2 问题）
- [ce:work] argument-hint 补充 [C] 和 [G] 参数说明（之前遗漏，用户无法从 hint 得知这两个标志的含义）
- [ce:review] 6.5a 执行顺序描述澄清：「Runs immediately after step 6」改为「Runs after step 6 routing normalization is complete (as a secondary normalization pass), before Patch Gate (6.5b)」

## [2.45.21] - 2026-04-09

### 修复（全量检查第五轮：6 个遗留问题）
- [ce:work] Phase -1 [G] 宣告矛盾修复：改为「不透传给内嵌 ce:review」与 Phase 3 注释一致（原文错误声明「将透传 [G]，Gemini 将参与审查」）
- [ce:work] Layer 1 步骤编号修复：两个「4.」改为正确的 4/5/6（执行 curl → 验证响应 → 成功/失败）
- [ce:work] Phase 2 Execute 步骤编号修复：第二个「6.」（Track Progress）改为「7.」
- [team-mode] BLOCKED 检查点路径修复：两处旧路径 `.ce-work-verification.json` 更新为 `.context/compound-engineering/ce-work-verification.json`
- [team-mode] 字段描述 + ce:plan 激活步骤：「Acceptance Criteria」改为「## 验收场景章节和 Unit Verification 字段」（与 ce:plan Phase 4.5 一致）
- [ce:plan] Phase 4.5 YAML 模板注释：required_invariants 示例更新为正确来源描述

## [2.45.20] - 2026-04-09

### 修复（第四轮：剩余 P2/P3 + Handoff 协议 + 文件路径）
- [ce:work] 修复 Phase -1 [C] 宣告文字（移除"透传给内嵌 ce:review"的错误声明）
- [ce:work] Phase 4 新增 Workflow Handoff（AskUserQuestion 三选一：代码审查/创建PR/完成）
- [ce:work] [PW] 孤立检测升级为 AskUserQuestion（从文字警告升级为 agent-native 交互）
- [ce:work] .context/compound-engineering/ce-work-verification.json 替代根目录放置（避免多 worktree 冲突，与 ce:review artifact 目录一致）
- [ce:work] 添加 Layer 3 + team 验证者 Hook 职责矩阵表（时机/范围/读取方式/失败行为）
- [ce:work] Phase 0 添加 [R]+[T] 组合交互行为说明
- [team-mode] 添加风险卫执行规范（时机/输入/匹配规则/用户拒绝处理）
- [team-mode] allowed_files 字段说明添加精确匹配规则（不支持通配符/目录前缀）
- [ce:review] Rule 4 添加 fixer subagent 执行步骤（命令式vs描述式验证/回滚逻辑）
- [ce:brainstorm] argument-hint 添加 [team:full] 说明

## [2.45.19] - 2026-04-09

### 修复（第三轮 + team 全量审核）
- [ce:work] Codex-P1: Phase 3 内嵌 ce:review 添加 [team] 透传，防止 Patch Gate 被绕过（安全漏洞修复）
- [ce:work] Codex-P2a: 移除内嵌 ce:review 的 [C]/[G] 透传（transparent pass 是净损失，降级 safe_auto 无实际收益）
- [ce:work] Codex-P2b/team-P1-001: Phase 3.5.0 情况A新增 task_id 比对，防止不同任务误继承旧验证状态
- [ce:work] P1-001: Phase 3.5.0 情况A添加 current_layer→Phase 跳转映射表
- [ce:work] task_id 生成添加输入清理规则（仅保留字母数字中文连字符下划线）
- [ce:work] P2-001: 澄清 verification_rounds 递增时机（每轮所有层完成后 +1），移除 Layer 0 超限时的错误提前 +1
- [ce:work] P2-002: 添加全层跳过→passes=true 路径（纯文档/无可执行验证场景）
- [ce:work] P2-003: Phase 3.5.3 添加两种 Layer 3 委派状态的 passes 判断规则
- [ce:work] P2-006: Phase 3 添加 [C]/[G]/[team] 参数拼接示例
- [ce:work] team-P2-001: Layer 1 修复重复步骤编号（第二个 "3." 改为 "4."）
- [ce:work] team-P1-002: Layer 1 认证 token 获取优先使用 TEST_ 前缀变量，避免误用生产凭证
- [ce:plan] Codex-P2c: Phase 4.5 执行时机改为 Phase 5.2 之后（确保合约与最终计划同步）
- [ce:plan] Codex-P2d/P2-005: required_invariants 提取来源改为 `## 验收场景` + Unit Verification 字段，不再引用不存在的 "Acceptance Criteria" 章节
- [ce:plan] P2-004: allowed_files 提取规则明确排除 Test/Move/Delete 类型文件
- [ce:review] P1-002: argument-hint 添加 [team:full] 说明

## [2.45.18] - 2026-04-09

### 修复
- [ce:work] Phase -1 重构 [PW] 检测为嵌套结构（消除多步依赖链），添加 Playwright MCP 可用性检查
- [ce:work] Phase -1 新增 [C]/[G] 检测并透传给内嵌 ce:review 调用
- [ce:work] Phase 3.5.0 添加先读后写逻辑，修复 session 恢复承诺无法实现的问题
- [ce:work] Phase 3.5.0 添加只读文件系统降级策略（内存状态模式）
- [ce:work] Layer 0 添加层内最大重试次数限制（3 次），防止无限循环
- [ce:work] Layer 1 添加认证端点识别优先级规则，不再依赖 AI 推断登录端点
- [ce:work] Layer 2 添加 agent-browser 两步调用说明（加载文档 + Bash 执行）
- [ce:work] [PW] argument-hint 改为主动式警告，明确前置条件（需 Playwright MCP Server）
- [ce:work] [R] 去重规则独立展开，不再引用 ce:brainstorm，明确跨 skill 不生效
- [ce:work] [T]+[team] BLOCKED 改为标准 AskUserQuestion，不再引用未定义的 team 检查点
- [ce:work] [T]+[team] Layer 3 边界定义明确（只核查跨任务维度），定义跨任务组合问题处理路径
- [ce:plan] Phase 4.5 添加 Load team-mode skill 指令
- [ce:plan] Phase 4.5 修复 plan_source_commit 时序问题，添加 Post-Phase-5 更新指南
- [ce:plan] argument-hint 添加 [team:full] 说明
- [team-mode] 添加 BLOCKED 检查点定义（[T]+[team] 同时激活时）
- [team-mode] 文档化 plan_source_commit 版本检测限制和启用步骤
- [team-mode] 降级行为表添加设计原因说明
- [team-mode] 明确 [team:full] 在 ce:brainstorm/review 中等同 [team]
- [team-mode] 添加并行 subagent 文件边界约束规则
- [team-mode] [T]+[team] 全局 Layer 3 补充定义
- [ce:review] [C]/[G] 参数描述修正：诚实说明不直接调用 Codex/Gemini，而是激活安全降级规则
- [ce:review] Patch Gate 扩展到 interactive 模式（原仅限 autofix），确保合约保护在默认模式生效
- [ce:review] argument-hint 添加 [team:full] 说明（等同 [team]）
- [ce:brainstorm] [R] 去重规则独立展开，添加跳过通知，明确跨 skill 不生效
- [ce:brainstorm] [team:full] 说明等同 [team]

---

## [2.45.14] - 2026-04-09

### Added

* **feat(ce-work)**: 新增 `[T]` 参数——四层自验证模式（Layer 0 CLI + Layer 1 API/DB + Layer 2 浏览器 + Layer 3 验收审查）
  * 完成标准从"代码写完"升级为"通过验证"
  * `[T]` 模式默认使用 agent-browser（低 token，30-50x 于 Playwright MCP）
* **feat(ce-work)**: 新增 `[PW]` 参数——显式启用 Playwright MCP 浏览器验证（仅在 `[T]` 时生效）
  * 适用于网络请求拦截、JS 执行、拖拽、文件上传等高精度场景
  * 用户显式控制，避免 token 浪费
* **feat(ce-work)**: 新增 `.ce-work-verification.json` 跨轮次验证状态持久化（已加入 .gitignore）
* **feat(ce-work)**: Layer 3"不信任实现者报告"原则——独立读文件，不依赖执行阶段自声明
* **feat(ce-plan)**: 新增 `## 验收场景` 章节模板——为 `ce:work [T]` 的 Layer 3 提供逐条核查标准

---

## [2.45.10] - 2026-04-08

### Added

* **feat(team-mode)**: 新增 `[team]` 参数 — 多代理协作稳定性框架，适用于 ce:brainstorm/plan/work/review
  * 单写者原则（Iron Law）：执行者是唯一可写共享代码的角色，其他角色只读
  * 合约白名单：`ce:plan [team]` 在 Phase 4.5 自动生成 `.team-contract.md`（allowed_files/forbidden_surfaces/required_invariants）
  * 验证者集成：`ce:work [team]` 每任务完成后自动运行验证者 Hook（集成测试 + 不变式检查）
  * Deterministic Patch Gate：`ce:review mode:autofix [team]` 在 Stage 5 执行规则引擎门控（不消耗额外 token）
  * 三个变体：`[team]`（3角色默认）/ `[team:light]`（2角色快速）/ `[team:full]`（4角色含风险卫）
  * `[P][team]` 组合支持：Party Mode 发散 → [team] 结构化验证（顺序执行）
* **feat(team-mode)**: 新增 `skills-custom/team-mode/SKILL.md` — overlay skill，定义角色规范、单写者原则、合约文件格式
* **feat(team-mode)**: 新增 `skills-custom/team-mode/templates/team-contract.md.tpl` — `.team-contract.md` 生成模板

### Fixed

* **fix(review-contract)**: 虚拟字段（`conclusion_type`/Tier 分类）现在由 `[team]` Patch Gate 自动消费 — "入口未接通、虚拟字段无消费者"问题已解决
* **fix(review-contract)**: 新增 Integration with [team] Mode 节，明确 Tier → Patch Gate 行为映射
* **fix(team-mode/ce-plan)**: 移除跨 skill 模板路径依赖——Phase 4.5 现在内联 .team-contract.md 格式，不再引用 `skills-custom/team-mode/templates/` 路径（修复 marketplace 安装时路径不可解析问题）
* **fix(team-mode/ce-review)**: Patch Gate 使用 `finding.file`（review schema 实际字段），替换伪字段 `patch_file`/`affected_files`；Tier 覆盖规则改为 TEAM_GATE_ENABLED 下无条件激活（不再依赖 review-contract skill 是否单独加载）
* **fix(team-mode/ce-work)**: 验证者 Hook 改为只报告失败，写入 `last_verification_failure` 由执行者负责——修复验证者违反单写者原则的矛盾
* **fix(plugin.json)**: 修正 description 中 custom overlays 数量（14→12，与实际一致）
* **fix(team-mode/ce-plan)**: Phase 4.5 触发条件移除 `[team:light]`（该模式设计为无合约，触发生成为语义矛盾）
* **fix(team-mode/ce-review)**: Patch Gate Rule 2 forbidden_surfaces 命中时降级目标从 `advisory` 改为 `gated_auto`，确保禁止区域的 finding 仍可被追踪（而非变为 report-only）
* **fix(team-mode/ce-work)**: 子代理 dispatch 时补充传递 team-mode 上下文（合约内容 + 角色约束），修复 subagent 模式下边界检查静默失效的问题
* **fix(team-mode/SKILL.md)**: 补充 `追溯审查`/`探索者`/`挑战者` 角色到角色定义表；移除未在 ce:brainstorm 中实现的 `[team:full]` 可行性审查；修正审查 agent 数量描述（"31个"→"多个"）；移除死字段 `patch_gate_enabled`

## [2.45.7] — 2026-04-08

### 修复与优化（P3 可选优化批次）

* **fix(codex-first-executor)**: 澄清 Gemini 策略 — 区分「审核视角」（已激活 `[G]`）与「执行器路由」（暂缓），修正"暂缓"措辞造成的误解
* **fix(codex-first-executor)**: `codex "$TASK_PROMPT"` 添加 `--` 分隔符防止参数注入（`codex -- "$TASK_PROMPT"`）
* **fix(review-contract)**: 为 `conclusion_type` 字段添加显式说明——此为本地 overlay 字段，不存在于上游 findings-schema.json
* **fix(user-first-design)**: 删除与全局 CLAUDE.md「UI 设计理念」章节重复的内容，改为指针引用
* **fix(check-handoff.sh)**: 将 `$SKIP_FILES` 和 `$EXTRA_COMMANDS` 改为 bash 数组，避免 word splitting 和 glob 展开风险
* **fix(bump-version.ps1)**: 新增 semver 格式验证，拒绝非 `X.Y.Z` 格式的版本号
* **fix(sync-codex-workflows.ps1)**: 将 `$CodexHome` 默认值改为函数体内 `Join-Path $HOME ".codex"`，避免参数默认值中的路径拼接问题
* **fix(check-versions.sh)**: 添加 jq null 值处理，防止字段缺失时静默使用 "null" 字符串进行比较
* **refactor**: 删除零引用私有 skill `root-cause-analysis`（功能已被 `systematic-debugging` 覆盖）
* **refactor**: 删除零引用私有 skill `review-prompt`（无任何引用）
* **chore**: 将 `technical_review.md` 重命名为 `technical-review.md`（符合 kebab-case 命名规范）

## [2.45.6] - 2026-04-08

### Bug Fixes

* **doctor.md**: 移除对不存在 scripts/doctor.sh 的依赖，改为直接调用现有脚本
* **review-contract**: anti-leniency 澄清为参考框架，非自动注入
* **deploy-docs.yml**: 修复监测和部署路径 docs
* **triage-prs.md**: allowed-tools 补充 Task/AskUserQuestion/Read
* **deprecated agents**: 为 security-sentinel/performance-oracle/data-integrity-guardian/data-migration-expert 添加废弃通知
* **intent-gate**: 移除小数相编号 Phase 0.5
* **ui-review-contract**: $PLAN_FILE 未定义变量修复
* **executor-capability-gate**: last_call 写入说明 + Check 5 简化

## [2.45.5] - 2026-04-08

### Security Fixes

* **codex-review-now.sh**: XML 标签隔离 diff 内容防止提示词注入
* **notify-sound.sh**: 改用环境变量传 PowerShell 路径防止注入
* **codex-review-now.sh**: 切换到 git 根目录 + TIMEOUT_SECONDS 整数验证
* **check-handoff.sh**: `grep -qF` 字面匹配防止文件名被当作正则
* **executor-capability-gate**: stat 跨平台兼容修复
* **patch-approval**: 移除不存在的 `--dry-run`，使用隔离目录方案

## [2.45.4] - 2026-04-08

### Bug Fixes

* **overlay**: 新增 overlay 技能触发时机注册表（plugins CLAUDE.md）
* **sync-targets**: 修复错误的 codex 安装命令，改用 sync-codex-workflows.ps1
* **docs**: 移除错误的 marketplace.json 版本号同步要求
* **ce-work-integration**: 修复 state.md.tpl 路径错误
* **compound-promotion-ladder**: 澄清为手动调用，非自动触发
* **task-bundle**: 补充 ce-work-integration overlay 加载说明
* **删除**: 移除零引用的 findings-triage/SKILL.md（与上游重复）

## [2.63.1](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.63.0...cli-v2.63.1) (2026-04-07)


### Miscellaneous Chores

* **cli:** Synchronize compound-engineering versions

## [2.63.0](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.62.1...cli-v2.63.0) (2026-04-06)


### Miscellaneous Chores

* **cli:** Synchronize compound-engineering versions

## [2.62.1](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.62.0...cli-v2.62.1) (2026-04-05)


### Bug Fixes

* **ce-brainstorm:** reduce token cost by extracting late-sequence content ([#511](https://github.com/EveryInc/compound-engineering-plugin/issues/511)) ([bdeb793](https://github.com/EveryInc/compound-engineering-plugin/commit/bdeb7935fcdb147b73107177769c2e968463d93f))
* **cli:** resolve repo-wide tsc --noEmit type errors ([#512](https://github.com/EveryInc/compound-engineering-plugin/issues/512)) ([3fa0c81](https://github.com/EveryInc/compound-engineering-plugin/commit/3fa0c815b286c9e11b28dc04c803529e73b79c1b))

## [2.62.0](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.61.0...cli-v2.62.0) (2026-04-03)


### Features

* **ce-plan:** reduce token usage by extracting conditional references ([#489](https://github.com/EveryInc/compound-engineering-plugin/issues/489)) ([fd562a0](https://github.com/EveryInc/compound-engineering-plugin/commit/fd562a0d0255d203d40fd53bb10d03a284a3c0e5))


### Bug Fixes

* **converters:** OpenCode subagent model and FQ agent name resolution ([#483](https://github.com/EveryInc/compound-engineering-plugin/issues/483)) ([577db53](https://github.com/EveryInc/compound-engineering-plugin/commit/577db53a2d2e237e900ef2079817cfe63df2d725))
* **converters:** remove invalid tools/infer from Copilot agent frontmatter ([#493](https://github.com/EveryInc/compound-engineering-plugin/issues/493)) ([6dcb4a3](https://github.com/EveryInc/compound-engineering-plugin/commit/6dcb4a3c553c94e95cb15b5af59aeb6693e6fd61))
* **mcp:** remove bundled context7 MCP server ([#486](https://github.com/EveryInc/compound-engineering-plugin/issues/486)) ([afdd9d4](https://github.com/EveryInc/compound-engineering-plugin/commit/afdd9d44651f834b1eed0b20e401ffbef5c8cd41))

## [2.61.0](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.60.0...cli-v2.61.0) (2026-04-01)


### Features

* **release:** document linked-versions policy ([#482](https://github.com/EveryInc/compound-engineering-plugin/issues/482)) ([96345ac](https://github.com/EveryInc/compound-engineering-plugin/commit/96345acf217333726af0dcfdaa24058a149365bb))
* **skill-design:** document skill file isolation and platform variable constraints ([#469](https://github.com/EveryInc/compound-engineering-plugin/issues/469)) ([0294652](https://github.com/EveryInc/compound-engineering-plugin/commit/0294652395cb62d5569f73ebfea543cfe8b514d6))


### Bug Fixes

* **converters:** preserve user config when writing MCP servers ([#479](https://github.com/EveryInc/compound-engineering-plugin/issues/479)) ([c65a698](https://github.com/EveryInc/compound-engineering-plugin/commit/c65a698d932d02e5fb4a948db4d000e21ed6ba4f))

## [2.60.0](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.59.0...cli-v2.60.0) (2026-03-31)


### Features

* **ce-brainstorm:** add conditional visual aids to requirements documents ([#437](https://github.com/EveryInc/compound-engineering-plugin/issues/437)) ([bd02ca7](https://github.com/EveryInc/compound-engineering-plugin/commit/bd02ca7df04cf2c1c6301de3774e99d283d3d3ca))
* **ce-compound:** add discoverability check for docs/solutions/ in instruction files ([#456](https://github.com/EveryInc/compound-engineering-plugin/issues/456)) ([5ac8a2c](https://github.com/EveryInc/compound-engineering-plugin/commit/5ac8a2c2c8c258458307e476d6693cc387deb27e))
* **ce-compound:** add track-based schema for bug vs knowledge learnings ([#445](https://github.com/EveryInc/compound-engineering-plugin/issues/445)) ([739109c](https://github.com/EveryInc/compound-engineering-plugin/commit/739109c03ccd45474331625f35730924d17f63ef))
* **ce-plan:** add conditional visual aids to plan documents ([#440](https://github.com/EveryInc/compound-engineering-plugin/issues/440)) ([4c7f51f](https://github.com/EveryInc/compound-engineering-plugin/commit/4c7f51f35bae56dd9c9dc2653372910c39b8b504))
* **ce-plan:** add interactive deepening mode for on-demand plan strengthening ([#443](https://github.com/EveryInc/compound-engineering-plugin/issues/443)) ([ca78057](https://github.com/EveryInc/compound-engineering-plugin/commit/ca78057241ec64f36c562e3720a388420bdb347f))
* **ce-review:** enforce table format, require question tool, fix autofix_class calibration ([#454](https://github.com/EveryInc/compound-engineering-plugin/issues/454)) ([847ce3f](https://github.com/EveryInc/compound-engineering-plugin/commit/847ce3f156a5cdf75667d9802e95d68e6b3c53a4))
* **ce-review:** improve signal-to-noise with confidence rubric, FP suppression, and intent verification ([#434](https://github.com/EveryInc/compound-engineering-plugin/issues/434)) ([03f5aa6](https://github.com/EveryInc/compound-engineering-plugin/commit/03f5aa65b098e2ab8e25670594e0f554ea3cafbe))
* **ce-work:** suggest branch rename when worktree name is meaningless ([#451](https://github.com/EveryInc/compound-engineering-plugin/issues/451)) ([e872e15](https://github.com/EveryInc/compound-engineering-plugin/commit/e872e15efa5514dcfea84a1a9e276bad3290cbc3))
* **cli-agent-readiness-reviewer:** add smart output defaults criterion ([#448](https://github.com/EveryInc/compound-engineering-plugin/issues/448)) ([a01a8aa](https://github.com/EveryInc/compound-engineering-plugin/commit/a01a8aa0d29474c031a5b403f4f9bfc42a23ad78))
* **converters:** centralize model field normalization across targets ([#442](https://github.com/EveryInc/compound-engineering-plugin/issues/442)) ([f93d10c](https://github.com/EveryInc/compound-engineering-plugin/commit/f93d10cf60a61b13c7765198d69f7c4cfa268ed6))
* **git-commit-push-pr:** add conditional visual aids to PR descriptions ([#444](https://github.com/EveryInc/compound-engineering-plugin/issues/444)) ([44e3e77](https://github.com/EveryInc/compound-engineering-plugin/commit/44e3e77dc039d31a86194b0254e4e92839d9d5e9))
* **git-commit-push-pr:** precompute shield badge version via skill preprocessing ([#464](https://github.com/EveryInc/compound-engineering-plugin/issues/464)) ([6ca7aef](https://github.com/EveryInc/compound-engineering-plugin/commit/6ca7aef7f33ebdf29f579cb4342c209d2bd40aad))
* **model:** add MiniMax provider prefix for cross-platform model normalization ([#463](https://github.com/EveryInc/compound-engineering-plugin/issues/463)) ([e372b43](https://github.com/EveryInc/compound-engineering-plugin/commit/e372b43d30378321ac815fe1ae101c1d5634d321))
* **resolve-pr-feedback:** add gated feedback clustering to detect systemic issues ([#441](https://github.com/EveryInc/compound-engineering-plugin/issues/441)) ([a301a08](https://github.com/EveryInc/compound-engineering-plugin/commit/a301a082057494e122294f4e7c1c3f5f87103f35))
* **skills:** clean up argument-hint across ce:* skills ([#436](https://github.com/EveryInc/compound-engineering-plugin/issues/436)) ([d2b24e0](https://github.com/EveryInc/compound-engineering-plugin/commit/d2b24e07f6f2fde11cac65258cb1e76927238b5d))
* **test-xcode:** add triggering context to skill description ([#466](https://github.com/EveryInc/compound-engineering-plugin/issues/466)) ([87facd0](https://github.com/EveryInc/compound-engineering-plugin/commit/87facd05dac94603780d75acb9da381dd7c61f1b))
* **testing:** close the testing gap in ce:work, ce:plan, and testing-reviewer ([#438](https://github.com/EveryInc/compound-engineering-plugin/issues/438)) ([35678b8](https://github.com/EveryInc/compound-engineering-plugin/commit/35678b8add6a603cf9939564bcd2df6b83338c52))


### Bug Fixes

* **ce-brainstorm:** distinguish verification from technical design in Phase 1.1 ([#465](https://github.com/EveryInc/compound-engineering-plugin/issues/465)) ([8ec31d7](https://github.com/EveryInc/compound-engineering-plugin/commit/8ec31d703fc9ed19bf6377da0a9a29da935b719d))
* **ce-compound:** require question tool for "What's next?" prompt ([#460](https://github.com/EveryInc/compound-engineering-plugin/issues/460)) ([9bf3b07](https://github.com/EveryInc/compound-engineering-plugin/commit/9bf3b07185a4aeb6490116edec48599b736dc86f))
* **ce-plan:** reinforce mandatory document-review after auto deepening ([#450](https://github.com/EveryInc/compound-engineering-plugin/issues/450)) ([42fa8c3](https://github.com/EveryInc/compound-engineering-plugin/commit/42fa8c3e084db464ee0e04673f7c38cd422b32d6))
* **ce-plan:** route confidence-gate pass to document-review ([#462](https://github.com/EveryInc/compound-engineering-plugin/issues/462)) ([1962f54](https://github.com/EveryInc/compound-engineering-plugin/commit/1962f546b5e5288c7ce5d8658f942faf71651c81))
* **ce-work:** make code review invocation mandatory by default ([#453](https://github.com/EveryInc/compound-engineering-plugin/issues/453)) ([7f3aba2](https://github.com/EveryInc/compound-engineering-plugin/commit/7f3aba29e84c3166de75438d554455a71f4f3c22))
* **document-review:** show contextual next-step in Phase 5 menu ([#459](https://github.com/EveryInc/compound-engineering-plugin/issues/459)) ([2b7283d](https://github.com/EveryInc/compound-engineering-plugin/commit/2b7283da7b48dc073670c5f4d116e58255f0ffcb))
* **git-commit-push-pr:** quiet expected no-pr gh exit ([#439](https://github.com/EveryInc/compound-engineering-plugin/issues/439)) ([1f49948](https://github.com/EveryInc/compound-engineering-plugin/commit/1f499482bc65456fa7dd0f73fb7f2fa58a4c5910))
* **resolve-pr-feedback:** add actionability filter and lower cluster gate to 3+ ([#461](https://github.com/EveryInc/compound-engineering-plugin/issues/461)) ([2619ad9](https://github.com/EveryInc/compound-engineering-plugin/commit/2619ad9f58e6c45968ec10d7f8aa7849fe43eb25))
* **review:** harden ce-review base resolution ([#452](https://github.com/EveryInc/compound-engineering-plugin/issues/452)) ([638b38a](https://github.com/EveryInc/compound-engineering-plugin/commit/638b38abd267d415ad2d6b72eba3dfe12beefad9))

## [2.59.0](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.58.1...cli-v2.59.0) (2026-03-29)


### Features

* **ce-review:** add headless mode for programmatic callers ([#430](https://github.com/EveryInc/compound-engineering-plugin/issues/430)) ([3706a97](https://github.com/EveryInc/compound-engineering-plugin/commit/3706a9764b6e73b7a155771956646ddef73f04a5))
* **ce-work:** accept bare prompts and add test discovery ([#423](https://github.com/EveryInc/compound-engineering-plugin/issues/423)) ([6dabae6](https://github.com/EveryInc/compound-engineering-plugin/commit/6dabae6683fb2c37dc47616f172835eacc105d11))
* **document-review:** collapse batch_confirm tier into auto ([#432](https://github.com/EveryInc/compound-engineering-plugin/issues/432)) ([0f5715d](https://github.com/EveryInc/compound-engineering-plugin/commit/0f5715d562fffc626ddfde7bd0e1652143710a44))
* **review:** make review mandatory across pipeline skills ([#433](https://github.com/EveryInc/compound-engineering-plugin/issues/433)) ([9caaf07](https://github.com/EveryInc/compound-engineering-plugin/commit/9caaf071d9b74fd938567542167768f6cdb7a56f))

## [2.58.1](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.58.0...cli-v2.58.1) (2026-03-28)


### Bug Fixes

* **release:** align cli and compound-engineering versions with linked-versions plugin ([0bd29c7](https://github.com/EveryInc/compound-engineering-plugin/commit/0bd29c7f2e930fc1198cc7ae833394bfabd47c40))

## [2.58.0](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.57.1...cli-v2.58.0) (2026-03-28)


### Features

* **document-review:** add headless mode for programmatic callers ([#425](https://github.com/EveryInc/compound-engineering-plugin/issues/425)) ([4e4a656](https://github.com/EveryInc/compound-engineering-plugin/commit/4e4a6563b4aa7375e9d1c54bd73442f3b675f100))

## [2.57.1](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.57.0...cli-v2.57.1) (2026-03-28)


### Bug Fixes

* **onboarding:** resolve section count contradiction with skip rule ([#421](https://github.com/EveryInc/compound-engineering-plugin/issues/421)) ([d2436e7](https://github.com/EveryInc/compound-engineering-plugin/commit/d2436e7c933129784c67799a5b9555bccce2e46d))

## [2.57.0](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.56.0...cli-v2.57.0) (2026-03-28)


### Features

* **ce-plan:** add decision matrix form, unchanged invariants, and risk table format ([#417](https://github.com/EveryInc/compound-engineering-plugin/issues/417)) ([ccb371e](https://github.com/EveryInc/compound-engineering-plugin/commit/ccb371e0b7917420f5ca2c58433f5fc057211f04))


### Bug Fixes

* **cli-agent-readiness-reviewer:** remove top-5 cap on improvements ([#419](https://github.com/EveryInc/compound-engineering-plugin/issues/419)) ([16eb8b6](https://github.com/EveryInc/compound-engineering-plugin/commit/16eb8b660790f8de820d0fba709316c7270703c1))
* **document-review:** enforce interactive questions and fix autofix classification ([#415](https://github.com/EveryInc/compound-engineering-plugin/issues/415)) ([d447296](https://github.com/EveryInc/compound-engineering-plugin/commit/d44729603da0c73d4959c372fac0198125a39c60))

## [2.56.0](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.55.0...cli-v2.56.0) (2026-03-27)


### Features

* add adversarial review agents for code and documents ([#403](https://github.com/EveryInc/compound-engineering-plugin/issues/403)) ([5e6cd5c](https://github.com/EveryInc/compound-engineering-plugin/commit/5e6cd5c90950588fb9b0bc3a5cbecba2a1387080))
* add CLI agent-readiness reviewer and principles guide ([#391](https://github.com/EveryInc/compound-engineering-plugin/issues/391)) ([13aa3fa](https://github.com/EveryInc/compound-engineering-plugin/commit/13aa3fa8465dce6c037e1bb8982a2edad13f199a))
* add project-standards-reviewer as always-on ce:review persona ([#402](https://github.com/EveryInc/compound-engineering-plugin/issues/402)) ([b30288c](https://github.com/EveryInc/compound-engineering-plugin/commit/b30288c44e500013afe30b34f744af57cae117db))
* **ce-brainstorm:** group requirements by logical concern, tighten autofix classification ([#412](https://github.com/EveryInc/compound-engineering-plugin/issues/412)) ([90684c4](https://github.com/EveryInc/compound-engineering-plugin/commit/90684c4e8272b41c098ef2452c40d86d460ea578))
* **ce-plan:** strengthen test scenario guidance across plan and work skills ([#410](https://github.com/EveryInc/compound-engineering-plugin/issues/410)) ([615ec5d](https://github.com/EveryInc/compound-engineering-plugin/commit/615ec5d3feb14785530bbfe2b4a50afe29ccbc47))
* **ce-review:** add base: and plan: arguments, extract scope detection ([#405](https://github.com/EveryInc/compound-engineering-plugin/issues/405)) ([914f9b0](https://github.com/EveryInc/compound-engineering-plugin/commit/914f9b0d9822786d9ba6dc2307a543ae5a25c6e9))
* **document-review:** smarter autofix, batch-confirm, and error/omission classification ([#401](https://github.com/EveryInc/compound-engineering-plugin/issues/401)) ([0863cfa](https://github.com/EveryInc/compound-engineering-plugin/commit/0863cfa4cbebcd121b0757abf374e5095d42f989))
* **onboarding:** add consumer perspective and split architecture diagrams ([#413](https://github.com/EveryInc/compound-engineering-plugin/issues/413)) ([31326a5](https://github.com/EveryInc/compound-engineering-plugin/commit/31326a54584a12c473944fa488bea26410fd6fce))


### Bug Fixes

* add strict YAML validation for plugin frontmatter ([#399](https://github.com/EveryInc/compound-engineering-plugin/issues/399)) ([0877b69](https://github.com/EveryInc/compound-engineering-plugin/commit/0877b693ced341cec699ea959dc39f8bd78f33ef))
* clarify commit prefix selection for markdown product code ([#407](https://github.com/EveryInc/compound-engineering-plugin/issues/407)) ([4a60ee2](https://github.com/EveryInc/compound-engineering-plugin/commit/4a60ee23b77c942111f3935d325ca5c80424ceb2))
* consolidate compound-docs into ce-compound skill ([#390](https://github.com/EveryInc/compound-engineering-plugin/issues/390)) ([daddb7d](https://github.com/EveryInc/compound-engineering-plugin/commit/daddb7d72f280a3bd9645c54d091844c198a324d))
* consolidate local dev README and fix shell aliases ([#396](https://github.com/EveryInc/compound-engineering-plugin/issues/396)) ([1bd63c2](https://github.com/EveryInc/compound-engineering-plugin/commit/1bd63c2c8931b63bcafe960ea6353372ea85512a))
* document SwiftUI Text link tap limitation in test-xcode skill ([#400](https://github.com/EveryInc/compound-engineering-plugin/issues/400)) ([6ddaec3](https://github.com/EveryInc/compound-engineering-plugin/commit/6ddaec3b6ed5b6a91aeaddadff3960714ef10dc1))
* harden git workflow skills with better state handling ([#406](https://github.com/EveryInc/compound-engineering-plugin/issues/406)) ([f83305e](https://github.com/EveryInc/compound-engineering-plugin/commit/f83305e22af09c37f452cf723c1b08bb0e7c8bdf))
* improve agent-native-reviewer with triage, prioritization, and stack-aware search ([#387](https://github.com/EveryInc/compound-engineering-plugin/issues/387)) ([e792166](https://github.com/EveryInc/compound-engineering-plugin/commit/e7921660ad42db8e9af56ec36f36ce8d1af13238))
* replace broken markdown link refs in skills ([#392](https://github.com/EveryInc/compound-engineering-plugin/issues/392)) ([506ad01](https://github.com/EveryInc/compound-engineering-plugin/commit/506ad01b4f056b0d8d0d440bfb7821f050aba156))
* sanitize colons in skill/agent names for Windows path compatibility ([#398](https://github.com/EveryInc/compound-engineering-plugin/issues/398)) ([b25480a](https://github.com/EveryInc/compound-engineering-plugin/commit/b25480af9eb1e69efa2fe30a8e7048f4c6aaa53c))

## [2.55.0](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.54.0...cli-v2.55.0) (2026-03-26)


### Features

* add branch-based plugin install for worktree workflows ([#395](https://github.com/EveryInc/compound-engineering-plugin/issues/395)) ([e09a742](https://github.com/EveryInc/compound-engineering-plugin/commit/e09a7426be6ba1cd86122e7519abfe3376849ade))


### Bug Fixes

* prevent orphaned opening paragraphs in PR descriptions ([#393](https://github.com/EveryInc/compound-engineering-plugin/issues/393)) ([4b44a94](https://github.com/EveryInc/compound-engineering-plugin/commit/4b44a94e23c8621771b8813caebce78060a61611))

## [2.54.0](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.53.0...cli-v2.54.0) (2026-03-26)


### Features

* add new `onboarding` skill to create onboarding guide for repo ([#384](https://github.com/EveryInc/compound-engineering-plugin/issues/384)) ([27b9831](https://github.com/EveryInc/compound-engineering-plugin/commit/27b9831084d69c4c8cf13d0a45c901268420de59))
* replace manual review agent config with ce:review delegation ([#381](https://github.com/EveryInc/compound-engineering-plugin/issues/381)) ([fed9fd6](https://github.com/EveryInc/compound-engineering-plugin/commit/fed9fd68db283c64ec11293f88a8ad7a6373e2fe))


### Bug Fixes

* add default-branch guard to commit skills ([#386](https://github.com/EveryInc/compound-engineering-plugin/issues/386)) ([31f07c0](https://github.com/EveryInc/compound-engineering-plugin/commit/31f07c00473e9d8bd6d447cf04081c0a9631e34a))
* one-step codex installs by preferring bundled plugins ([#383](https://github.com/EveryInc/compound-engineering-plugin/issues/383)) ([f819e43](https://github.com/EveryInc/compound-engineering-plugin/commit/f819e435a54f5d7df558df5a6bee1e616a5da837))
* scope commit-push-pr descriptions to full branch diff ([#385](https://github.com/EveryInc/compound-engineering-plugin/issues/385)) ([355e739](https://github.com/EveryInc/compound-engineering-plugin/commit/355e7392b21a28c8725f87a8f9c473a86543ce4a))

## [2.53.0](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.52.0...cli-v2.53.0) (2026-03-25)


### Features

* add git commit and branch helper skills ([#378](https://github.com/EveryInc/compound-engineering-plugin/issues/378)) ([fe08af2](https://github.com/EveryInc/compound-engineering-plugin/commit/fe08af2b417b707b6d3192a954af7ff2ab0fe667))
* improve `resolve-pr-feedback` skill ([#379](https://github.com/EveryInc/compound-engineering-plugin/issues/379)) ([2ba4f3f](https://github.com/EveryInc/compound-engineering-plugin/commit/2ba4f3fd58d4e57dfc6c314c2992c18ba1fb164b))
* improve commit-push-pr skill with net-result focus and badging ([#380](https://github.com/EveryInc/compound-engineering-plugin/issues/380)) ([efa798c](https://github.com/EveryInc/compound-engineering-plugin/commit/efa798c52cb9d62e9ef32283227a8df68278ff3a))
* integrate orphaned stack-specific reviewers into ce:review ([#375](https://github.com/EveryInc/compound-engineering-plugin/issues/375)) ([ce9016f](https://github.com/EveryInc/compound-engineering-plugin/commit/ce9016fac5fde9a52753cf94a4903088f05aeece))


### Bug Fixes

* guard CONTEXTUAL_RISK_FLAGS lookup against prototype pollution ([#377](https://github.com/EveryInc/compound-engineering-plugin/issues/377)) ([8ebc77b](https://github.com/EveryInc/compound-engineering-plugin/commit/8ebc77b8e6c71e5bef40fcded9131c4457a387d7))

## [2.52.0](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.51.0...cli-v2.52.0) (2026-03-25)


### Features

* add consolidation support and overlap detection to `ce:compound` and `ce:compound-refresh` skills ([#372](https://github.com/EveryInc/compound-engineering-plugin/issues/372)) ([fe27f85](https://github.com/EveryInc/compound-engineering-plugin/commit/fe27f85810268a8e713ef2c921f0aec1baf771d7))
* minimal config for conductor support ([#373](https://github.com/EveryInc/compound-engineering-plugin/issues/373)) ([aad31ad](https://github.com/EveryInc/compound-engineering-plugin/commit/aad31adcd3d528581e8b00e78943b21fbe2c47e8))
* optimize `ce:compound` speed and effectiveness ([#370](https://github.com/EveryInc/compound-engineering-plugin/issues/370)) ([4e3af07](https://github.com/EveryInc/compound-engineering-plugin/commit/4e3af079623ae678b9a79fab5d1726d78f242ec2))
* promote `ce:review-beta` to stable `ce:review` ([#371](https://github.com/EveryInc/compound-engineering-plugin/issues/371)) ([7c5ff44](https://github.com/EveryInc/compound-engineering-plugin/commit/7c5ff445e3065fd13e00bcd57041f6c35b36f90b))
* rationalize todo skill names and optimize skills ([#368](https://github.com/EveryInc/compound-engineering-plugin/issues/368)) ([2612ed6](https://github.com/EveryInc/compound-engineering-plugin/commit/2612ed6b3d86364c74dc024e4ce35dde63fefbf6))

## [2.51.0](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.50.0...cli-v2.51.0) (2026-03-24)


### Features

* add `ce:review-beta` with structured persona pipeline ([#348](https://github.com/EveryInc/compound-engineering-plugin/issues/348)) ([e932276](https://github.com/EveryInc/compound-engineering-plugin/commit/e9322768664e194521894fe770b87c7dabbb8a22))
* promote ce:plan-beta and deepen-plan-beta to stable ([#355](https://github.com/EveryInc/compound-engineering-plugin/issues/355)) ([169996a](https://github.com/EveryInc/compound-engineering-plugin/commit/169996a75e98a29db9e07b87b0911cc80270f732))
* redesign `document-review` skill with persona-based review ([#359](https://github.com/EveryInc/compound-engineering-plugin/issues/359)) ([18d22af](https://github.com/EveryInc/compound-engineering-plugin/commit/18d22afde2ae08a50c94efe7493775bc97d9a45a))

## [2.50.0](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.49.0...cli-v2.50.0) (2026-03-23)


### Features

* **ce-work:** add Codex delegation mode ([#328](https://github.com/EveryInc/compound-engineering-plugin/issues/328)) ([341c379](https://github.com/EveryInc/compound-engineering-plugin/commit/341c37916861c8bf413244de72f83b93b506575f))
* improve `feature-video` skill with GitHub native video upload ([#344](https://github.com/EveryInc/compound-engineering-plugin/issues/344)) ([4aa50e1](https://github.com/EveryInc/compound-engineering-plugin/commit/4aa50e1bada07e90f36282accb3cd81134e706cd))
* rewrite `frontend-design` skill with layered architecture and visual verification ([#343](https://github.com/EveryInc/compound-engineering-plugin/issues/343)) ([423e692](https://github.com/EveryInc/compound-engineering-plugin/commit/423e69272619e9e3c14750f5219cbf38684b6c96))


### Bug Fixes

* quote frontend-design skill description ([#353](https://github.com/EveryInc/compound-engineering-plugin/issues/353)) ([86342db](https://github.com/EveryInc/compound-engineering-plugin/commit/86342db36c0d09b65afe11241e095dda2ad2cdb0))

## [2.49.0](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.48.0...cli-v2.49.0) (2026-03-22)


### Features

* add execution mode toggle and context pressure bounds to parallel skills ([#336](https://github.com/EveryInc/compound-engineering-plugin/issues/336)) ([216d6df](https://github.com/EveryInc/compound-engineering-plugin/commit/216d6dfb2c9320c3354f8c9f30e831fca74865cd))
* fix skill transformation pipeline across all targets ([#334](https://github.com/EveryInc/compound-engineering-plugin/issues/334)) ([4087e1d](https://github.com/EveryInc/compound-engineering-plugin/commit/4087e1df82138f462a64542831224e2718afafa7))
* improve reproduce-bug skill, sync agent-browser, clean up redundant skills ([#333](https://github.com/EveryInc/compound-engineering-plugin/issues/333)) ([affba1a](https://github.com/EveryInc/compound-engineering-plugin/commit/affba1a6a0d9320b529d429ad06fd5a3b5200bd8))


### Bug Fixes

* gitignore .context/ directory for Conductor ([#331](https://github.com/EveryInc/compound-engineering-plugin/issues/331)) ([0f6448d](https://github.com/EveryInc/compound-engineering-plugin/commit/0f6448d81cbc47e66004b4ecb8fb835f75aeffe2))

## [2.48.0](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.47.0...cli-v2.48.0) (2026-03-22)


### Features

* **git-worktree:** auto-trust mise and direnv configs in new worktrees ([#312](https://github.com/EveryInc/compound-engineering-plugin/issues/312)) ([cfbfb67](https://github.com/EveryInc/compound-engineering-plugin/commit/cfbfb6710a846419cc07ad17d9dbb5b5a065801c))
* make skills platform-agnostic across coding agents ([#330](https://github.com/EveryInc/compound-engineering-plugin/issues/330)) ([52df90a](https://github.com/EveryInc/compound-engineering-plugin/commit/52df90a16688ee023bbdb203969adcc45d7d2ba2))

## [2.47.0](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.46.0...cli-v2.47.0) (2026-03-20)


### Features

* improve `repo-research-analyst` by adding a structured technology scan ([#327](https://github.com/EveryInc/compound-engineering-plugin/issues/327)) ([1c28d03](https://github.com/EveryInc/compound-engineering-plugin/commit/1c28d0321401ad50a51989f5e6293d773ac1a477))


### Bug Fixes

* **skills:** update ralph-wiggum references to ralph-loop in lfg/slfg ([#324](https://github.com/EveryInc/compound-engineering-plugin/issues/324)) ([ac756a2](https://github.com/EveryInc/compound-engineering-plugin/commit/ac756a267c5e3d5e4ceb2f99939dbb93491ac4d2))

## [2.46.0](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.45.0...cli-v2.46.0) (2026-03-20)


### Features

* add optional high-level technical design to plan-beta skills ([#322](https://github.com/EveryInc/compound-engineering-plugin/issues/322)) ([3ba4935](https://github.com/EveryInc/compound-engineering-plugin/commit/3ba4935926b05586da488119f215057164d97489))


### Bug Fixes

* **ci:** add npm registry auth to release publish job ([#319](https://github.com/EveryInc/compound-engineering-plugin/issues/319)) ([3361a38](https://github.com/EveryInc/compound-engineering-plugin/commit/3361a38108991237de51050283e781be847c6bd3))

## [2.45.0](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.44.0...cli-v2.45.0) (2026-03-19)


### Features

* edit resolve_todos_parallel skill for complete todo lifecycle ([#292](https://github.com/EveryInc/compound-engineering-plugin/issues/292)) ([88c89bc](https://github.com/EveryInc/compound-engineering-plugin/commit/88c89bc204c928d2f36e2d1f117d16c998ecd096))
* integrate claude code auto memory as supplementary data source for ce:compound and ce:compound-refresh ([#311](https://github.com/EveryInc/compound-engineering-plugin/issues/311)) ([5c1452d](https://github.com/EveryInc/compound-engineering-plugin/commit/5c1452d4cc80b623754dd6fe09c2e5b6ae86e72e))


### Bug Fixes

* add cursor-marketplace as release-please component ([#315](https://github.com/EveryInc/compound-engineering-plugin/issues/315)) ([838aeb7](https://github.com/EveryInc/compound-engineering-plugin/commit/838aeb79d069b57a80d15ff61d83913919b81aef))

## [2.44.0](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.43.2...cli-v2.44.0) (2026-03-18)


### Features

* **plugin:** add execution posture signaling to ce:plan-beta and ce:work ([#309](https://github.com/EveryInc/compound-engineering-plugin/issues/309)) ([748f72a](https://github.com/EveryInc/compound-engineering-plugin/commit/748f72a57f713893af03a4d8ed69c2311f492dbd))

## [2.43.2](https://github.com/EveryInc/compound-engineering-plugin/compare/cli-v2.43.1...cli-v2.43.2) (2026-03-18)


### Bug Fixes

* enable release-please labeling so it can find its own PRs ([a7d6e3f](https://github.com/EveryInc/compound-engineering-plugin/commit/a7d6e3fbba862d4e8b4e1a0510f0776e9e274b89))
* re-enable changelogs so release PRs accumulate correctly ([516bcc1](https://github.com/EveryInc/compound-engineering-plugin/commit/516bcc1dc4bf4e4756ae08775806494f5b43968a))
* reduce release-please search depth from 500 to 50 ([f1713b9](https://github.com/EveryInc/compound-engineering-plugin/commit/f1713b9dcd0deddc2485e8cf0594266232bf0019))
* remove close-stale-PR step that broke release creation ([178d6ec](https://github.com/EveryInc/compound-engineering-plugin/commit/178d6ec282512eaee71ab66d45832d22d75353ec))

## Changelog

Release notes now live in GitHub Releases for this repository:

https://github.com/EveryInc/compound-engineering-plugin/releases

Multi-component releases are published under component-specific tags such as:

- `cli-vX.Y.Z`
- `compound-engineering-vX.Y.Z`
- `coding-tutor-vX.Y.Z`
- `marketplace-vX.Y.Z`

Do not add new release entries here. New release notes are managed by release automation in GitHub.
