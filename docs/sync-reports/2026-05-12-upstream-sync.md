---
date: 2026-05-12
window_days: 30
source_config: docs/sync-reports/upstream-repos.json
status: draft
---

# Upstream Sync Report — 2026-05-12

## Summary

本次扫描覆盖 7 个上游/参考仓库，窗口为最近 30 天。`EveryInc/compound-engineering-plugin` 与本仓库差异最大：上游已经完成更彻底的 **skills/agents `ce-` 前缀化、commands 清空、原生插件安装、Codex manifests、核心流程压缩和大量 review/plan/work 修正**。

| Repo | Strategy | Status | Relevance | Notes |
|---|---|---:|---|---|
| EveryInc/compound-engineering-plugin | git-native | success | 高 | 主上游，存在大量可整合更新；不可直接全量 merge，需要选择性移植，避免覆盖本地中文化/私有 overlay |
| bmad-code-org/BMAD-METHOD | github-api | success | 中 | installer / platform 支持 / TOML customize / investigate skill 有参考价值 |
| obra/superpowers | github-api | success | 中 | Codex plugin sync tooling 与 committed Codex plugin files 方向和本项目 `/sil` 高相关 |
| anthropics/claude-code | releases | success-empty | 中 | 30 天内 release API 未返回公开 release；运行时仍需参考本地 CLI 行为 |
| Yeachan-Heo/oh-my-claudecode | github-api | success | 低-中 | 有同宿主插件参考价值，需二次人工筛选 |
| code-yeongyu/oh-my-openagent | github-api | success | 低-中 | OpenAgent/OpenCode 方向参考，非直接合并对象 |
| fengshao1227/ccg-workflow | github-api | success | 低 | 近期更新少 |

## High-Relevance Findings

### 1. 上游已经基本取消 `commands/` 作为主入口

证据：`git ls-tree upstream/main plugins/compound-engineering/commands` 为空；上游 `plugins/compound-engineering/skills/` 下存在大量 `ce-*` skills。

本仓库现状：仍保留 `plugins/compound-engineering/commands/ce/{doctor,pr,sync-upstream}.md`，主流程已在 `skills/ce-*/SKILL.md`。

建议：
- 主流程保持全部 skill 化；这是上游方向。
- 工具命令是否迁移成 skill 需要单独规划；如果迁移，必须删除 command 同名壳层，避免 Claude Code 补全重复。
- 修复本机重复补全时，重点不是源码，而是清理/刷新已安装插件缓存中的旧 `commands/ce/{brainstorm,plan,work,review,...}.md`。

### 2. 上游统一 `ce-` 前缀并测试强制

相关提交：`5c0ec91 refactor(cli)!: rename all skills and agents to consistent ce- prefix (#503)`、`71d23d1 test: enforce ce- prefix on skills and agents (#748)`。

影响：
- 上游 skill 目录是 `ce-plan`、`ce-work`，用户入口仍可通过 frontmatter 暴露为 `/ce:plan` 或上游约定入口。
- agents 也扁平化并统一 `ce-*.agent.md`。

建议：暂不直接整体重命名本地 agents，因为当前项目已有大量本地 custom overlay 和中文文档依赖旧路径；应单独创建迁移计划。

### 3. ce-plan / ce-brainstorm / ce-work 核心流程有多轮可靠性修正

高相关提交：
- `60c1c93 fix(ce-plan): compress synthesis confirmation to prose + call-outs (#819)`
- `be2efd7 fix(ce-plan): render Implementation Units as headings, not bulleted list items (#766)`
- `15c1cde fix(ce-plan): close synthesis drift in rich-context invocations (#729)`
- `0c515c0 fix(ce-plan): inline post-generation menu routing so option 1 actually starts /ce-work (#715)`
- `41e7f72 feat(ce-brainstorm,ce-plan): surface agent's scope synthesis before doc-write (#705)`
- `304a975 feat(ce-brainstorm): probe rigor gaps with prose before Phase 2 (#677)`
- `494313e fix(ce-brainstorm): enforce Interaction Rules in universal flow (#669)`
- `053c1db fix(ce-work): codify worktree isolation for parallel subagent dispatch (#698)`
- `5cae4d1 fix(ce-work,ce-work-beta): add safety checks for parallel subagent dispatch (#557)`

建议：这些应优先选择性移植到本地 `ce-brainstorm` / `ce-plan` / `ce-work`，但要保留本地 `[T][V][R]`、Codex/Gemini、中文 handoff、Harness Fusion overlay。

### 4. ce-review / code-review pipeline 有大量稳定性更新

高相关提交：
- `d217660 fix(review): default to harness-native code review, escalate on risk (#721)`
- `d69a772 fix(review): queue reviewers when subagent slots fill (#716)`
- `e856756 fix(ce-code-review): keep finding numbers stable (#754)`
- `c7fc674 fix(review): escape literal pipes in finding table cells (#779)`
- `ad9577e fix(ce-code-review): tighten autofix_class rubric (#695)`
- `520a9eb fix(code-review): grant Write to JSON-pipeline reviewer agents (#741)`
- `9751d1 fix(ce-code-review): restate model override at dispatch point (#681)`

建议：优先移植“稳定 finding 编号、表格 pipe escaping、reviewer 排队、autofix 分类边界”这类局部规则；暂不直接覆盖本地 review contract。

### 5. Codex target / `/sil` 相关上游变化明显

相关提交：
- `60b66dd feat: convert hooks to .codex/hooks.json for Codex target (#742)`
- `3ed4a4f feat(codex): native plugin install manifests + agents-only converter (#616)`
- `ed778e6 fix(converters): preserve Codex config on no-MCP install (#564)`
- `ee8e402 fix(converters): preserve Codex agent sidecar scripts (#563)`

参考仓库 `obra/superpowers` 也有：
- `6efe32c Use committed Codex plugin files in sync script`
- `34c17ae sync-to-codex-plugin: seed interface.defaultPrompt (#1180)`
- `bc25777 sync-to-codex-plugin: anchor EXCLUDES patterns to source root`

建议：本项目已有“只同步 3 个 Codex workflow skills”的本地策略，不应直接采用上游全插件 Codex target；但可以吸收：
- committed Codex files 作为源；
- exclude patterns 锚定到 source root；
- 保留用户现有 Codex 配置；
- hooks 转 `.codex/hooks.json` 的思想需单独评估。

### 6. 新增上游功能候选

可考虑引入或对照实现：
- `ce-simplify-code`：简化近期代码改动。
- `ce-strategy` / `ce-product-pulse`：PM/策略类 skills。
- `ce-riffrec-feedback-analysis`：反馈分析技能。
- `ce-sessions`：session history 类工具，本地未必需要。
- `docs/skills/*`：用户向 skill 文档，上游已新增整套文档。

建议：先不一次性引入全部新 skill。优先级：
1. `ce-simplify-code`：和现有 `simplify` skill 功能接近，需要比较是否重复。
2. `docs/skills/*`：可作为 README 拆分参考，但本地中文文档已有体系。
3. `ce-strategy` / `ce-product-pulse`：若本地要强化 ideate/brainstorm 产品层，可引入。

## Recommended Integration Priority

### P0 — 立即处理

1. 确认本地安装态刷新到当前源码版本，消除旧 command 壳层导致的 `/ce:*` 重复补全。
2. 将“全部 skill 化仍显示中文”的规则写进开发规范：中文来自 `SKILL.md` frontmatter `description` / `argument-hint`。
3. 运行 `/sil` 或等价脚本，验证 Codex 三 workflow skill 没漂移。

### P1 — 本轮建议整合

1. 从上游选择性移植 `ce-plan` / `ce-brainstorm` / `ce-work` 的可靠性规则。
2. 从上游选择性移植 `ce-review` 的局部稳定性规则。
3. 对 `scripts/sync-codex-workflows.ps1` 对照 superpowers / upstream 的 Codex sync 经验，补强保留配置、路径锚定、committed source 约束。

### P2 — 另开计划

1. 评估 agents 扁平化和 `ce-*.agent.md` 迁移。
2. 评估是否删除剩余 `commands/ce/{doctor,pr,sync-upstream}.md` 并迁移为 skills。
3. 评估新增上游 skills 是否适合中文化引入。

## Noise Filtered

过滤或降低优先级：release commits、dependabot/chore、纯文档翻译、BMAD installer 发布细节、参考仓库中与 Claude Code 插件表面无关的 commits。

## Raw Data

原始采集文件位于 `.context/upstream-sync-raw/`：
- `everyinc-commits.tsv`
- `everyinc-diff-name-status.tsv`
- `bmad-code-org__BMAD-METHOD-commits.tsv`
- `obra__superpowers-commits.tsv`
- `Yeachan-Heo__oh-my-claudecode-commits.tsv`
- `code-yeongyu__oh-my-openagent-commits.tsv`
- `fengshao1227__ccg-workflow-commits.tsv`
