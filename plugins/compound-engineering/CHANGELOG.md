# Changelog

All notable changes to the compound-engineering plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.42.1] - 2026-02-15

### Fixed
- **Codex/Gemini 模型升级** — 所有 CLI 调用升级为最新模型（Codex: `gpt-5.3-codex`，Gemini: `gemini-3-pro-preview`）
- **Gemini CLI 兼容性修复** — 移除不兼容的 `--approval-mode plan` 参数（新版 Gemini CLI 需实验性功能）
- **安全文档修正** — 删除 gemini.md 中 `-p` 模式只读的错误声明，替换为准确的安全提示
- **Shell 注入风险修复** — gemini-review-now.sh 中 `bash -c` 改用环境变量传递路径，消除引号注入风险
- **模型版本可配置化** — 脚本提取 `CODEX_MODEL`/`GEMINI_MODEL` 环境变量，支持 `CODEX_MODEL=xxx ./scripts/codex-review-now.sh` 覆盖
- **文档一致性** — 修复 review.md 和 gemini-review-now.sh 中的过时描述

### Summary
- 29 agents, 31 commands, 23 skills, 1 MCP server
- 基于三方代码审查（Claude + Codex + Gemini）发现并修复 P1/P2/P3 问题

---

## [2.42.0] - 2026-02-11

### Added
- **Memory frontmatter** — 为 6 个研究型/架构型 agents 添加 `memory: project/user`，启用跨会话知识积累
- **PDF pages 支持** — document-review skill 现在支持大型 PDF 分页读取
- **Fast mode 引导** — workflows:review 和 workflows:work 命令添加性能优化提示

### Summary
- 29 agents (6 with memory), 31 commands, 23 skills, 1 MCP server

## [2.41.0] - 2026-02-10

### Critical Fix

- **修复 context token 预算溢出 bug** — 插件使用了 316% 的 16K 字符预算，导致组件被静默排除
  - 压缩 29 个 agent 描述（examples 从 frontmatter 移到 body），节省 ~35,600 字符
  - 14 个命令添加 `disable-model-invocation: true` 标志
  - 8 个 skill 添加 `disable-model-invocation: true` 标志
  - 预算使用从 316% 降至 ~72%，实现 77% token 减少

### Added

- **`schema-drift-detector` agent** — 新增数据库 schema 漂移检测 agent（来自上游 v2.29.0）
- **`orchestrating-swarms` skill** — 多 agent 编排指南，1718 行参考文档（来自上游 v2.30.0）
- **`document-review` skill** — brainstorm/plan 文档审查 skill
- **`resolve-pr-parallel` skill** — PR 评论并行解决（从 command 升级为 skill）
- **`/slfg` command** — Swarm 模式自主工程工作流
- **`/technical_review` command** — 技术审查命令
- **`/triage-prs` command** — PR 分类和合并管理

### Fixed

- **Hook crash 修复** — 修复 hook 条目没有 matcher 时的崩溃（上游 #160）
- **Subagent 中间文件防护** — `/workflows:compound` 防止 subagent 写入中间文件（上游 #150）
- **配置备份** — 覆盖配置文件前先备份（上游 #119）

### Summary

- 29 agents, 31 commands, 23 skills, 1 MCP server
- 基于上游 v2.29.0 - v2.30.0 选择性整合，保留全部中文文档和自定义功能

---

## [2.40.1] - 2026-02-04

### Changed

- **`/workflows:work` Subagent 分支安全增强** — 整合 superpowers 最佳实践
  - Subagent-Driven 模式禁止在默认分支（main/master）上执行
  - 添加 Branch Safety Guard 前置检查
  - 强化 worktree 推荐：≥2 任务时强烈推荐 worktree 隔离

### Fixed

- **上游 `#142` protect plan files** — 防止审查过程意外删除 plan 文件（合并自 upstream/main）

### Summary

- 28 agents, 29 commands, 20 skills, 1 MCP server

---

## [2.40.0] - 2026-02-04

### Added

- **`/workflows:sync-upstream` 命令** — 上游仓库智能同步检测
  - 角色化策略：parent(git-native) / reference(github-api) / runtime(releases)
  - 可扩展配置：`upstream-repos.json` 支持动态添加/移除监控仓库
  - 结构化报告：带 YAML frontmatter，支持 `/workflows:plan` 自动发现
  - 噪音过滤：自动排除 chore/bump/dependabot/merge commits
  - 交互式讨论：评估后可直接创建整合计划或执行合并
  - 语音通知：发现重要更新时自动语音提醒

### Summary

- 28 agents, 29 commands, 20 skills, 1 MCP server

---

## [2.39.0] - 2026-02-04

### Added

- **`/workflows:brainstorm [C][G]` 支持** - 在方案探索阶段调用 Codex/Gemini 外部方案咨询
  - `[C]` 参数：Phase 2 后自动调用 Codex 方案咨询，寻找最优解
  - `[G]` 参数：Phase 2 后自动调用 Gemini 方案咨询，寻找最优解
  - `[P]` `[C]` `[G]` 三者正交兼容，可任意组合、无先后顺序
  - 结果整合进 brainstorm 文档的「外部咨询」小节
  - 使用 `<!-- CLAUDE-CODE-ONLY-START/END -->` 排除，不同步到 Codex/Gemini 格式

### Summary

- 28 agents, 28 commands, 20 skills, 1 MCP server

---

## [2.38.1] - 2026-02-04

### 修复

- **SessionStart hook 跨平台修复** - 改为 prompt hook，避免 Windows 无 bash 时报错卡住

### Summary

- 28 agents, 28 commands, 20 skills, 1 MCP server

---
## [2.38.0] - 2026-02-04

### Added

- **`/gemini` 命令** - 向 Gemini 寻求更优方案和最优解
  - Claude 智能分析当前对话上下文（调试、设计、选型、重构等）
  - 自动构建结构化 prompt，附上 Claude 当前方案供 Gemini 批判性评估
  - 引导 Gemini 评估：是否最优解、有无替代方案、性价比、潜在风险
  - 通过 `gemini --approval-mode plan -o json` 只读模式调用 Gemini CLI

- **`/codex` 命令** - 向 Codex 寻求更优方案和最优解
  - 与 `/gemini` 相同的智能上下文构建和批判性评估策略
  - 通过 `codex exec --output-last-message` 调用 Codex CLI
  - 综合对比分析，推荐性价比最优的方案

### Changed

- **挑战式咨询设计** - 核心理念是「寻求更优解」而非仅仅「第二意见」：
  - 自动附上 Claude 当前方案，让外部工具做对比评判
  - 引导外部工具从最优解、替代方案、性价比、维护风险四维度分析
  - 结果展示以「方案对比与最优解分析」为核心，不回避分歧

### Summary

- 28 agents, 28 commands, 20 skills, 1 MCP server

---

## [2.37.0] - 2026-02-03

### Added

- **Gemini CLI 集成** - `/workflows:review [G]` 支持调用 Gemini 进行额外代码审核
  - 使用 `gemini --approval-mode plan -o json` 非交互模式（基于 Gemini 官方建议）
  - 通过 stdin 管道传递 prompt，支持 1M+ tokens（不截断 diff）
  - 使用系统 `timeout` 命令处理超时
  - 新增 `scripts/gemini-review-now.sh` 脚本

- **多工具协同审核** - `/workflows:review [C][G]` 同时调用 Codex 和 Gemini
  - 综合三方审核结果（Claude + Codex + Gemini）
  - 多方一致的发现优先级更高

- **转换器智能过滤** - 转换到 Codex/Gemini 格式时自动过滤 `[C]` `[G]` 参数说明
  - 新增 `src/utils/filter-claude-code-only.ts` 公共过滤函数
  - 支持 `<!-- CLAUDE-CODE-ONLY-START/END -->` 标记块过滤

### Changed

- **`/workflows:review`** - 更新参数解析支持 `[G]` 标志
- 更新 Prerequisites 包含 Gemini CLI 安装说明

### Summary

- 28 agents, 26 commands, 20 skills, 1 MCP server

---

## [2.36.1] - 2026-02-03

### Changed

- **Codex 审核优化** - 解决长时间无响应问题
  - 改用 `codex exec --json` 非交互模式（[官方推荐](https://developers.openai.com/codex/noninteractive)）
  - 支持 JSONL 事件流，实时显示进度（thread.started、turn.started 等）
  - 后台执行 + 5 分钟超时保护
  - 超时后提供清晰的备选方案（增加超时时间、手动运行、查看部分输出）
  - 更新 `scripts/codex-review-now.sh` v2 版本

### Fixed

- 修复 Codex CLI 调用可能卡住 10+ 分钟无反馈的问题（[Issue #4775](https://github.com/openai/codex/issues/4775)）

### Summary

- 28 agents, 26 commands, 20 skills, 1 MCP server

---

## [2.36.0] - 2026-02-03

### Added

- **跨工具经验库系统** - 支持 Claude Code、Codex、Gemini 共享经验库
  - 统一全局目录：`~/.compound/solutions/`（跨项目、跨工具）
  - 三级优先级：`COMPOUND_SOLUTIONS_HOME` > `~/.compound/solutions/` > `docs/solutions/`
  - 跨平台支持：Windows、macOS、Linux 路径自动解析
  - 首次运行自动检测、创建目录、注入配置
  - 项目标记文件：`.compound/config.json`

### Changed

- **`/workflows:compound`** - 添加 Environment Setup 自动化流程
  - Step 0: 自动检测并创建经验库系统
  - Step 0.1: Codex/Gemini CLI 同步说明
- **`learnings-researcher` agent** - 支持搜索全局 + 项目两个经验库
- **项目 `CLAUDE.md`** - 更新搜索说明为双目录搜索

### Summary

- 28 agents, 26 commands, 20 skills, 1 MCP server

---

## [2.35.0] - 2026-02-02

### Added

- **Codex 可选审核集成到 `/workflows:review`** - 通过 `[C]` 参数自动触发 Codex 额外审核
  - 命令参数添加 `[C]` 即可自动执行（如 `/workflows:review [C]` 或 `/workflows:review 123 [C]`）
  - Codex 结果**同步显示在当前会话**，而非写入临时文件
  - 自动整合 Claude 多代理审核 + Codex 审核结果
  - 提供综合建议：双方一致的发现优先级更高

### Changed

- **`/workflows:review` 命令** - 添加 `[C]` 参数和 Step 7: Codex 额外审核
  - 参数格式：`/workflows:review [目标] [C]`
  - 有 `[C]` → 自动调用 Codex
  - 无 `[C]` → 跳过 Codex 审核

### Summary

- 28 agents, 26 commands, 20 skills, 1 MCP server

---

## [2.34.0] - 2026-02-02

### Removed

- **Codex Auto-Review Integration** - Removed Stop hook that automatically triggered Codex review
  - Deleted `codex-review.sh`, `codex-review.ps1`, `codex-review-wrapper.sh`
  - Removed Stop hook from `hooks.json`
  - **Reason**: Auto-review was incomplete (results written to temp file with no consumption mechanism), triggered too frequently (any file change), and required users to have Codex CLI installed

### Recommendation

For code review, use `/workflows:review` or manually run `codex review --uncommitted` when needed.

### Summary

- 28 agents, 26 commands, 20 skills, 1 MCP server

---

## [2.33.0] - 2026-02-02

### Added

- **Codex Auto-Review Integration** - Stop hook triggers automatic code review via Codex CLI
  - `codex-review.sh` - Bash script for Unix/Git Bash
  - `codex-review.ps1` - PowerShell script for Windows (called by wrapper)
  - `codex-review-wrapper.sh` - Cross-platform wrapper (auto-detects OS)
  - Automatically runs `codex review --uncommitted` when Claude Code session ends
  - Includes untracked new files in review scope
  - Prevents infinite loop via `stop_hook_active` flag detection

### Fixed

- **Untracked files missing from review** - Scripts now include `git ls-files --others --exclude-standard` to capture new files
- **Codex review mode** - Changed from interactive prompt to `codex review --uncommitted` for non-blocking execution
- **jq dependency** - Added fallback to grep when jq is not installed

### Requirements

- **Codex CLI**: `npm install -g @openai/codex`
- **Windows users**: Git Bash required (included with Git for Windows)

### Summary

- 28 agents, 26 commands, 20 skills, 1 MCP server

---

## [2.32.0] - 2026-02-02

### Added

- **Subagent-Driven Development** - Automatic execution mode selection in `/workflows:work`
  - 1 task → Standard mode (single agent)
  - ≥2 tasks → Subagent-Driven mode (fresh context per task)
  - Two-stage review: spec-compliance → code quality
  - Human checkpoints every 3 tasks

- **Bite-Sized Task format** - Mandatory format in `/workflows:plan`
  - 2-5 minute atomic tasks
  - Exact file paths with line numbers
  - Complete code (not pseudocode)
  - Specific verification steps

- **Solution documentation** - New docs in `docs/solutions/`
  - `subagent-driven-workflow-integration.md` - Integration guide
  - `skill-vs-agent-invocation.md` - Skill vs Agent usage patterns

### Changed

- **`/workflows:work` command** - Added automatic execution mode detection (lines 19-47) and Subagent batch execution (lines 155-206)
- **`/workflows:plan` command** - Added Bite-Sized Task format requirement (lines 123-184)
- **`skill-checking-protocol.md`** - Added auto execution mode explanation

### Summary

- 28 agents, 26 commands, 20 skills, 1 MCP server

---

## [2.31.0] - 2026-02-01

### Changed

- Internal improvements and bug fixes

### Summary

- 28 agents, 26 commands, 20 skills, 1 MCP server

---

## [2.30.0] - 2026-02-01

### Added

- **`party-mode` skill** - Multi-agent collaborative discussion framework integrated with brainstorming
  - Enables 2-3 AI agents to discuss from different expert perspectives
  - Includes 14 pre-defined agent personas (architects, developers, PMs, designers, etc.)
  - Intelligent agent selection based on discussion topic
  - Natural cross-talk between agents (referencing, challenging, building on points)
  - Seamless integration with `/workflows:brainstorm` via `[P]` trigger

### Changed

- **`/workflows:brainstorm` command** - Added Party Mode entry point for multi-perspective discussions

### Summary

- 28 agents, 26 commands, 17 skills, 1 MCP server

---

## [2.29.0] - 2026-02-01

### Fixed

- **Workflow command descriptions** - Changed circle numbers (①②③④⑤) to ASCII format (Step 1: Step 2: etc.) for better terminal compatibility
- **Version sync issue** - Fixed marketplace.json version mismatch that prevented plugin updates via Marketplace
- **README.md** - Updated Commands count from 24 to 26

### Changed

- **CLAUDE.md (root)** - Added version sync warning and quick check command
- **CLAUDE.md (plugin)** - Added marketplace.json to version sync requirements

### Summary

- 28 agents, 26 commands, 16 skills, 1 MCP server

---

## [2.28.0] - 2026-01-21

### Added

- **`/workflows:brainstorm` command** - Guided ideation flow to expand options quickly (#101)

### Changed

- **`/workflows:plan` command** - Smarter research decision logic before deep dives (#100)
- **Research checks** - Mandatory API deprecation validation in research flows (#102)
- **Docs** - Call out experimental OpenCode/Codex providers and install defaults
- **CLI defaults** - `install` pulls from GitHub by default and writes OpenCode/Codex output to global locations

### Merged PRs

- [#102](https://github.com/EveryInc/compound-engineering-plugin/pull/102) feat(research): add mandatory API deprecation validation
- [#101](https://github.com/EveryInc/compound-engineering-plugin/pull/101) feat: Add /workflows:brainstorm command and skill
- [#100](https://github.com/EveryInc/compound-engineering-plugin/pull/100) feat(workflows:plan): Add smart research decision logic

### Contributors

Huge thanks to the community contributors who made this release possible! 🙌

- **[@tmchow](https://github.com/tmchow)** - Brainstorm workflow, research decision logic (2 PRs)
- **[@jaredmorgenstern](https://github.com/jaredmorgenstern)** - API deprecation validation

---

## [2.27.0] - 2026-01-20

### Added

- **`/workflows:plan` command** - Interactive Q&A refinement phase (#88)
  - After generating initial plan, now offers to refine with targeted questions
  - Asks up to 5 questions about ambiguous requirements, edge cases, or technical decisions
  - Incorporates answers to strengthen the plan before finalization

### Changed

- **`/workflows:work` command** - Incremental commits and branch safety (#93)
  - Now commits after each completed task instead of batching at end
  - Added branch protection checks before starting work
  - Better progress tracking with per-task commits

### Fixed

- **`dhh-rails-style` skill** - Fixed broken markdown table formatting (#96)
- **Documentation** - Updated hardcoded year references from 2025 to 2026 (#86, #91)

### Contributors

Huge thanks to the community contributors who made this release possible! 🙌

- **[@tmchow](https://github.com/tmchow)** - Interactive Q&A for plans, incremental commits, year updates (3 PRs!)
- **[@ashwin47](https://github.com/ashwin47)** - Markdown table fix
- **[@rbouschery](https://github.com/rbouschery)** - Documentation year update

### Summary

- 27 agents, 23 commands, 14 skills, 1 MCP server

---

## [2.26.5] - 2026-01-18

### Changed

- **`/workflows:work` command** - Now marks off checkboxes in plan document as tasks complete
  - Added step to update original plan file (`[ ]` → `[x]`) after each task
  - Ensures no checkboxes are left unchecked when work is done
  - Keeps plan as living document showing progress

---

## [2.26.4] - 2026-01-15

### Changed

- **`/workflows:work` command** - PRs now include Compound Engineered badge
  - Updated PR template to include badge at bottom linking to plugin repo
  - Added badge requirement to quality checklist
  - Badge provides attribution and link to the plugin that created the PR

---

## [2.26.3] - 2026-01-14

### Changed

- **`design-iterator` agent** - Now auto-loads design skills at start of iterations
  - Added "Step 0: Discover and Load Design Skills (MANDATORY)" section
  - Discovers skills from ~/.claude/skills/, .claude/skills/, and plugin cache
  - Maps user context to relevant skills (Swiss design → swiss-design skill, etc.)
  - Reads SKILL.md files to load principles into context before iterating
  - Extracts key principles: grid specs, typography rules, color philosophy, layout principles
  - Skills are applied throughout ALL iterations for consistent design language

---

## [2.26.2] - 2026-01-14

### Changed

- **`/test-browser` command** - Clarified to use agent-browser CLI exclusively
  - Added explicit "CRITICAL: Use agent-browser CLI Only" section
  - Added warning: "DO NOT use Chrome MCP tools (mcp__claude-in-chrome__*)"
  - Added Step 0: Verify agent-browser installation before testing
  - Added full CLI reference section at bottom
  - Added Next.js route mapping patterns

---

## [2.26.1] - 2026-01-14

### Changed

- **`best-practices-researcher` agent** - Now checks skills before going online
  - Phase 1: Discovers and reads relevant SKILL.md files from plugin, global, and project directories
  - Phase 2: Only goes online for additional best practices if skills don't provide enough coverage
  - Phase 3: Synthesizes all findings with clear source attribution (skill-based > official docs > community)
  - Skill mappings: Rails → dhh-rails-style, Frontend → frontend-design, AI → agent-native-architecture, etc.
  - Prioritizes curated skill knowledge over external sources for trivial/common patterns

---

## [2.26.0] - 2026-01-14

### Added

- **`/lfg` command** - Full autonomous engineering workflow
  - Orchestrates complete feature development from plan to PR
  - Runs: plan → deepen-plan → work → review → resolve todos → test-browser → feature-video
  - Uses ralph-loop for autonomous completion
  - Migrated from local command, updated to use `/test-browser` instead of `/playwright-test`

### Summary

- 27 agents, 21 commands, 14 skills, 1 MCP server

---

## [2.25.0] - 2026-01-14

### Added

- **`agent-browser` skill** - Browser automation using Vercel's agent-browser CLI
  - Navigate, click, fill forms, take screenshots
  - Uses ref-based element selection (simpler than Playwright)
  - Works in headed or headless mode

### Changed

- **Replaced Playwright MCP with agent-browser** - Simpler browser automation across all browser-related features:
  - `/test-browser` command - Now uses agent-browser CLI with headed/headless mode option
  - `/feature-video` command - Uses agent-browser for screenshots
  - `design-iterator` agent - Browser automation via agent-browser
  - `design-implementation-reviewer` agent - Screenshot comparison
  - `figma-design-sync` agent - Design verification
  - `bug-reproduction-validator` agent - Bug reproduction
  - `/review` workflow - Screenshot capabilities
  - `/work` workflow - Browser testing

- **`/test-browser` command** - Added "Step 0" to ask user if they want headed (visible) or headless browser mode

### Removed

- **Playwright MCP server** - Replaced by agent-browser CLI (simpler, no MCP overhead)
- **`/playwright-test` command** - Renamed to `/test-browser`

### Summary

- 27 agents, 20 commands, 14 skills, 1 MCP server

---

## [2.23.2] - 2026-01-09

### Changed

- **`/reproduce-bug` command** - Enhanced with Playwright visual reproduction:
  - Added Phase 2 for visual bug reproduction using browser automation
  - Step-by-step guide for navigating to affected areas
  - Screenshot capture at each reproduction step
  - Console error checking
  - User flow reproduction with clicks, typing, and snapshots
  - Better documentation structure with 4 clear phases

### Summary

- 27 agents, 21 commands, 13 skills, 2 MCP servers

---

## [2.23.1] - 2026-01-08

### Changed

- **Agent model inheritance** - All 26 agents now use `model: inherit` so they match the user's configured model. Only `lint` keeps `model: haiku` for cost efficiency. (fixes #69)

### Summary

- 27 agents, 21 commands, 13 skills, 2 MCP servers

---

## [2.23.0] - 2026-01-08

### Added

- **`/agent-native-audit` command** - Comprehensive agent-native architecture review
  - Launches 8 parallel sub-agents, one per core principle
  - Principles: Action Parity, Tools as Primitives, Context Injection, Shared Workspace, CRUD Completeness, UI Integration, Capability Discovery, Prompt-Native Features
  - Each agent produces specific score (X/Y format with percentage)
  - Generates summary report with overall score and top 10 recommendations
  - Supports single principle audit via argument

### Summary

- 27 agents, 21 commands, 13 skills, 2 MCP servers

---

## [2.22.0] - 2026-01-05

### Added

- **`rclone` skill** - Upload files to S3, Cloudflare R2, Backblaze B2, and other cloud storage providers

### Changed

- **`/feature-video` command** - Enhanced with:
  - Better ffmpeg commands for video/GIF creation (proper scaling, framerate control)
  - rclone integration for cloud uploads
  - Screenshot copying to project folder
  - Improved upload options workflow

### Summary

- 27 agents, 20 commands, 13 skills, 2 MCP servers

---

## [2.21.0] - 2026-01-05

### Fixed

- Version history cleanup after merge conflict resolution

### Summary

This release consolidates all recent work:
- `/feature-video` command for recording PR demos
- `/deepen-plan` command for enhanced planning
- `create-agent-skills` skill rewrite (official spec compliance)
- `agent-native-architecture` skill major expansion
- `dhh-rails-style` skill consolidation (merged dhh-ruby-style)
- 27 agents, 20 commands, 12 skills, 2 MCP servers

---

## [2.20.0] - 2026-01-05

### Added

- **`/feature-video` command** - Record video walkthroughs of features using Playwright

### Changed

- **`create-agent-skills` skill** - Complete rewrite to match Anthropic's official skill specification

### Removed

- **`dhh-ruby-style` skill** - Merged into `dhh-rails-style` skill

---

## [2.19.0] - 2025-12-31

### Added

- **`/deepen-plan` command** - Power enhancement for plans. Takes an existing plan and runs parallel research sub-agents for each major section to add:
  - Best practices and industry patterns
  - Performance optimizations
  - UI/UX improvements (if applicable)
  - Quality enhancements and edge cases
  - Real-world implementation examples

  The result is a deeply grounded, production-ready plan with concrete implementation details.

### Changed

- **`/workflows:plan` command** - Added `/deepen-plan` as option 2 in post-generation menu. Added note: if running with ultrathink enabled, automatically run deepen-plan for maximum depth.

## [2.18.0] - 2025-12-25

### Added

- **`agent-native-architecture` skill** - Added **Dynamic Capability Discovery** pattern and **Architecture Review Checklist**:

  **New Patterns in mcp-tool-design.md:**
  - **Dynamic Capability Discovery** - For external APIs (HealthKit, HomeKit, GraphQL), build a discovery tool (`list_*`) that returns available capabilities at runtime, plus a generic access tool that takes strings (not enums). The API validates, not your code. This means agents can use new API capabilities without code changes.
  - **CRUD Completeness** - Every entity the agent can create must also be readable, updatable, and deletable. Incomplete CRUD = broken action parity.

  **New in SKILL.md:**
  - **Architecture Review Checklist** - Pushes reviewer findings earlier into the design phase. Covers tool design (dynamic vs static, CRUD completeness), action parity (capability map, edit/delete), UI integration (agent → UI communication), and context injection.
  - **Option 11: API Integration** - New intake option for connecting to external APIs like HealthKit, HomeKit, GraphQL
  - **New anti-patterns:** Static Tool Mapping (building individual tools for each API endpoint), Incomplete CRUD (create-only tools)
  - **Tool Design Criteria** section added to success criteria checklist

  **New in shared-workspace-architecture.md:**
  - **iCloud File Storage for Multi-Device Sync** - Use iCloud Documents for your shared workspace to get free, automatic multi-device sync without building a sync layer. Includes implementation pattern, conflict handling, entitlements, and when NOT to use it.

### Philosophy

This update codifies a key insight for **agent-native apps**: when integrating with external APIs where the agent should have the same access as the user, use **Dynamic Capability Discovery** instead of static tool mapping. Instead of building `read_steps`, `read_heart_rate`, `read_sleep`... build `list_health_types` + `read_health_data(dataType: string)`. The agent discovers what's available, the API validates the type.

Note: This pattern is specifically for agent-native apps following the "whatever the user can do, the agent can do" philosophy. For constrained agents with intentionally limited capabilities, static tool mapping may be appropriate.

---

## [2.17.0] - 2025-12-25

### Enhanced

- **`agent-native-architecture` skill** - Major expansion based on real-world learnings from building the Every Reader iOS app. Added 5 new reference documents and expanded existing ones:

  **New References:**
  - **dynamic-context-injection.md** - How to inject runtime app state into agent system prompts. Covers context injection patterns, what context to inject (resources, activity, capabilities, vocabulary), implementation patterns for Swift/iOS and TypeScript, and context freshness.
  - **action-parity-discipline.md** - Workflow for ensuring agents can do everything users can do. Includes capability mapping templates, parity audit process, PR checklists, tool design for parity, and context parity guidelines.
  - **shared-workspace-architecture.md** - Patterns for agents and users working in the same data space. Covers directory structure, file tools, UI integration (file watching, shared stores), agent-user collaboration patterns, and security considerations.
  - **agent-native-testing.md** - Testing patterns for agent-native apps. Includes "Can Agent Do It?" tests, the Surprise Test, automated parity testing, integration testing, and CI/CD integration.
  - **mobile-patterns.md** - Mobile-specific patterns for iOS/Android. Covers background execution (checkpoint/resume), permission handling, cost-aware design (model tiers, token budgets, network awareness), offline handling, and battery awareness.

  **Updated References:**
  - **architecture-patterns.md** - Added 3 new patterns: Unified Agent Architecture (one orchestrator, many agent types), Agent-to-UI Communication (shared data store, file watching, event bus), and Model Tier Selection (fast/balanced/powerful).

  **Updated Skill Root:**
  - **SKILL.md** - Expanded intake menu (now 10 options including context injection, action parity, shared workspace, testing, mobile patterns). Added 5 new agent-native anti-patterns (Context Starvation, Orphan Features, Sandbox Isolation, Silent Actions, Capability Hiding). Expanded success criteria with agent-native and mobile-specific checklists.

- **`agent-native-reviewer` agent** - Significantly enhanced with comprehensive review process covering all new patterns. Now checks for action parity, context parity, shared workspace, tool design (primitives vs workflows), dynamic context injection, and mobile-specific concerns. Includes detailed anti-patterns, output format template, quick checks ("Write to Location" test, Surprise test), and mobile-specific verification.

### Philosophy

These updates operationalize a key insight from building agent-native mobile apps: **"The agent should be able to do anything the user can do, through tools that mirror UI capabilities, with full context about the app state."** The failure case that prompted these changes: an agent asked "what reading feed?" when a user said "write something in my reading feed"—because it had no `publish_to_feed` tool and no context about what "feed" meant.

## [2.16.0] - 2025-12-21

### Enhanced

- **`dhh-rails-style` skill** - Massively expanded reference documentation incorporating patterns from Marc Köhlbrugge's Unofficial 37signals Coding Style Guide:
  - **controllers.md** - Added authorization patterns, rate limiting, Sec-Fetch-Site CSRF protection, request context concerns
  - **models.md** - Added validation philosophy, let it crash philosophy (bang methods), default values with lambdas, Rails 7.1+ patterns (normalizes, delegated types, store accessor), concern guidelines with touch chains
  - **frontend.md** - Added Turbo morphing best practices, Turbo frames patterns, 6 new Stimulus controllers (auto-submit, dialog, local-time, etc.), Stimulus best practices, view helpers, caching with personalization, broadcasting patterns
  - **architecture.md** - Added path-based multi-tenancy, database patterns (UUIDs, state as records, hard deletes, counter caches), background job patterns (transaction safety, error handling, batch processing), email patterns, security patterns (XSS, SSRF, CSP), Active Storage patterns
  - **gems.md** - Added expanded what-they-avoid section (service objects, form objects, decorators, CSS preprocessors, React/Vue), testing philosophy with Minitest/fixtures patterns

### Credits

- Reference patterns derived from [Marc Köhlbrugge's Unofficial 37signals Coding Style Guide](https://github.com/marckohlbrugge/unofficial-37signals-coding-style-guide)

## [2.15.2] - 2025-12-21

### Fixed

- **All skills** - Fixed spec compliance issues across 12 skills:
  - Reference files now use proper markdown links (`[file.md](./references/file.md)`) instead of backtick text
  - Descriptions now use third person ("This skill should be used when...") per skill-creator spec
  - Affected skills: agent-native-architecture, andrew-kane-gem-writer, compound-docs, create-agent-skills, dhh-rails-style, dspy-ruby, every-style-editor, file-todos, frontend-design, gemini-imagegen

### Added

- **CLAUDE.md** - Added Skill Compliance Checklist with validation commands for ensuring new skills meet spec requirements

## [2.15.1] - 2025-12-18

### Changed

- **`/workflows:review` command** - Section 7 now detects project type (Web, iOS, or Hybrid) and offers appropriate testing. Web projects get `/playwright-test`, iOS projects get `/xcode-test`, hybrid projects can run both.

## [2.15.0] - 2025-12-18

### Added

- **`/xcode-test` command** - Build and test iOS apps on simulator using XcodeBuildMCP. Automatically detects Xcode project, builds app, launches simulator, and runs test suite. Includes retries for flaky tests.

- **`/playwright-test` command** - Run Playwright browser tests on pages affected by current PR or branch. Detects changed files, maps to affected routes, generates/runs targeted tests, and reports results with screenshots.

