---
type: sync-report
date: 2026-04-07
scan_mode: full
repos_checked: 4
repos_with_updates: 4
items:
  - repo: "EveryInc/compound-engineering-plugin"
    relevance: high
    action: pending
    new_releases: 2
    new_commits: 270
  - repo: "bmad-code-org/BMAD-METHOD"
    relevance: medium
    action: pending
    new_releases: 4
    new_commits: 90
  - repo: "obra/superpowers"
    relevance: high
    action: pending
    new_releases: 4
    new_commits: 80
  - repo: "anthropics/claude-code"
    relevance: medium
    action: pending
    new_releases: 19
    new_commits: 0
---

# 上游同步检测报告

**日期**: 2026-04-07
**检测范围**: 最近 30 天（自 2026-03-08）

## 摘要

| 仓库 | 新 Release | 新 Commits | 相关度 | 建议动作 |
|------|-----------|-----------|--------|----------|
| EveryInc/compound-engineering-plugin | release-please 自动版本 | ~270 | **高** | 需要合并 |
| bmad-code-org/BMAD-METHOD | v6.1.0 → v6.2.2 | ~90 | 中 | 选择性参考 |
| obra/superpowers | v5.0.4 → v5.0.7 | ~80 | **高** | 需要同步 |
| anthropics/claude-code | v2.1.72 → v2.1.92 | — | 中 | 关注新功能 |

## 详细分析

### EveryInc/compound-engineering-plugin (parent)

**上次同步**: 42cc74c（约 2026-03-10）
**当前 upstream/main**: 9a82222（2026-04-06）
**差异**: ~270 commits

#### 高相关变更（直接影响本仓库功能）

| 变更 | 类型 | 相关性 | 理由 | 建议 |
|------|------|--------|------|------|
| feat(ce-plan,ce-brainstorm): universal planning for non-software tasks (#519) | feat | **高** | 本仓库 fork 了 plan/brainstorm，此功能扩展了适用范围 | 必须合并 |
| feat(slack-researcher): add Slack research agent (#495) | feat | 中 | 新功能，但依赖 Slack MCP | 参考 |
| fix(review,work): omit mode parameter in subagent dispatch (#522) | fix | **高** | 修复权限问题，影响 review 和 work 技能 | 必须合并 |
| feat(ce-review): promote ce:review-beta to stable (#371) | feat | **高** | review 技能全面重写，本仓库的 review 已过时 | 必须合并 |
| feat(ce-plan): promote ce:plan-beta to stable (#355) | feat | **高** | plan 技能全面重写 | 必须合并 |
| refactor: merge deepen-plan into ce:plan (#404) | refactor | **高** | deepen-plan 合并为 plan 的子功能 | 必须合并 |
| feat: add adversarial review agents (#403) | feat | **高** | 新增审查代理，增强 review 管线 | 必须合并 |
| feat(document-review): redesign with persona-based review (#359) | feat | **高** | document-review 全面重写 | 必须合并 |
| feat: add ce:compound-refresh skill (#bd3088a) | feat | **高** | 新技能，经验库维护 | 必须合并 |
| refactor: migrate commands to skills directory structure (#241) | refactor | **高** | 目录结构变更，commands → skills | 必须合并 |
| feat: make skills platform-agnostic (#330) | feat | **高** | 跨平台支持改进 | 必须合并 |
| fix: sanitize colons in skill/agent names for Windows (#398) | fix | **高** | Windows 兼容性修复 | 必须合并 |
| feat(ce-work): accept bare prompts and add test discovery (#423) | feat | **高** | work 技能增强 | 必须合并 |
| fix(ce-brainstorm): reduce token cost (#511, #bdeb793) | fix | 中 | 性能优化 | 建议合并 |
| fix(document-review): multiple fixes (#507, #509, #523, #524) | fix | 中 | document-review 稳定性修复 | 建议合并 |
| feat(ce-compound): track-based schema for bug vs knowledge (#445) | feat | 中 | compound 技能增强 | 建议合并 |
| feat: add git commit and branch helper skills (#378) | feat | 中 | 新的 git 工具技能 | 建议合并 |
| feat(converters): centralize model field normalization (#442) | feat | 中 | 转换器改进 | 建议合并 |
| feat: add claude-permissions-optimizer skill (#298) | feat | 中 | 新技能 | 建议合并 |
| feat(ce-ideate): add issue-grounded ideation (#282) | feat | 中 | 新的 ideate 技能 | 建议合并 |
| fix(mcp): remove bundled context7 MCP server (#486) | fix | 中 | 移除内置 context7 | 注意 |

#### 噪音过滤（已排除）

- ~25 个 `chore: release main` / `chore(release)` commits
- ~15 个 `Merge pull request` / `Merge branch` commits
- 多个 `semantic-release-bot` 自动版本 commits

#### 架构变更提醒

1. **commands → skills 迁移**: 上游已将所有 commands 迁移至 skills 目录结构，这是**破坏性结构变更**
2. **release-please 替代 semantic-release**: 发布系统已切换
3. **review/plan 全面重写**: ce:review-beta 和 ce:plan-beta 已提升为稳定版
4. **deepen-plan 合并**: 不再是独立技能
5. **document-review 重写**: 基于 persona 的审查管线

---

### bmad-code-org/BMAD-METHOD (reference)

#### Release Notes

| Release | 日期 | 重点 |
|---------|------|------|
| v6.2.2 | 2026-03-26 | 路径修复、模块定义路径修正 |
| v6.2.1 | 2026-03-24 | agent-manifest 修复、CLI 参数空格修复 |
| v6.2.0 | 2026-03-15 | 技能结构重构、hook 修复、新增平台支持 |
| v6.1.0 | 2026-03-13 | Junie/KiloCoder 平台支持、PRFAQ 技能 |

#### 相关变更

| 变更 | 类型 | 相关性 | 理由 | 建议 |
|------|------|--------|------|------|
| feat: add bmad-checkpoint-preview skill (#2145) | feat | 中 | 检查点预览机制，可参考设计 | 参考 |
| feat(quick-dev): planning artifact awareness (#2185) | feat | 中 | 计划文档感知，可借鉴 | 参考 |
| refactor(party-mode): consolidate into single SKILL.md (#2160) | refactor | 中 | 本仓库有类似的 party-mode 技能 | 参考 |
| feat: add .claude-plugin marketplace and plugin metadata (#2136) | feat | 中 | marketplace 元数据格式参考 | 参考 |
| refactor: consolidate plugin.json into marketplace.json (#2137) | refactor | 中 | 与本仓库的版本管理方式相关 | 参考 |
| feat: add Junie platform support (#2142) | feat | 低 | 本仓库暂无 Junie 需求 | 暂不需要 |
| docs(zh-cn): 多个中文文档更新 | docs | 低 | BMAD 的中文文档，非本仓库 | 暂不需要 |
| refactor(installer): 多个重构 (#2077-#2084) | refactor | 低 | BMAD 内部安装器重构 | 暂不需要 |

---

### obra/superpowers (reference)

#### Release Notes

| Release | 日期 | 重点 |
|---------|------|------|
| v5.0.7 | 2026-03-31 | Copilot CLI 支持、OpenCode 修复 |
| v5.0.6 | 2026-03-25 | inline self-review、brainstorm server 重构、owner-PID 修复 |
| v5.0.5 | 2026-03-17 | brainstorm server ESM 修复、Windows PID 修复 |
| v5.0.4 | 2026-03-17 | review loop 优化、OpenCode 一键安装 |

#### 相关变更

| 变更 | 类型 | 相关性 | 理由 | 建议 |
|------|------|--------|------|------|
| feat: add Copilot CLI tool mapping and install (#8b16692) | feat | **高** | 本仓库直接使用 superpowers 技能，Copilot 支持影响兼容性 | 需要同步 |
| Replace subagent review loops with inline self-review (#e6221a4) | refactor | **高** | 审查循环从 subagent 改为内联，影响本仓库的 review 技能行为 | 需要同步 |
| docs: add Codex App compatibility spec (PRI-823) | docs | **高** | Codex 兼容性设计，影响本仓库的 Codex 同步机制 | 需要同步 |
| fix: Windows brainstorm server lifecycle (#f34ee47) | fix | **高** | Windows 兼容性修复，本仓库在 Windows 上使用 | 需要同步 |
| fix: stop firing SessionStart hook on --resume (#d19703b) | fix | **高** | hook 行为修复，影响本仓库的 PeonPing hooks | 需要同步 |
| Add Gemini CLI tool mapping and support (#21a774e) | feat | 中 | Gemini CLI 支持，扩展平台覆盖 | 建议同步 |
| Zero-dep brainstorm server rewrite (#7619570-#8d9b94e) | refactor | 中 | brainstorm server 不再依赖 node_modules | 建议同步 |
| docs: add Codex named agent dispatch mapping (#2b1bfe5) | docs | 中 | Codex agent 调度映射 | 参考 |
| fix(writing-skills): correct frontmatter claim (#4fd9aa2) | fix | 中 | 技能前置元数据修复 | 建议同步 |
| fix(hooks): replace heredoc with printf for bash 5.3+ (#537ec64) | fix | 中 | bash 兼容性修复 | 建议同步 |

---

### anthropics/claude-code (runtime)

#### Release Notes

| Release | 日期 |
|---------|------|
| v2.1.92 | 2026-04-04 |
| v2.1.91 | 2026-04-02 |
| v2.1.90 | 2026-04-01 |
| v2.1.89 | 2026-04-01 |
| v2.1.87 | 2026-03-29 |
| v2.1.86 | 2026-03-27 |
| v2.1.85 | 2026-03-26 |
| v2.1.84 | 2026-03-26 |
| v2.1.83 | 2026-03-25 |
| v2.1.81 | 2026-03-20 |
| v2.1.80 | 2026-03-19 |
| v2.1.79 | 2026-03-18 |
| v2.1.78 | 2026-03-17 |
| v2.1.77 | 2026-03-17 |
| v2.1.76 | 2026-03-14 |
| v2.1.75 | 2026-03-13 |
| v2.1.74 | 2026-03-12 |
| v2.1.73 | 2026-03-11 |
| v2.1.72 | 2026-03-10 |

**说明**: claude-code 的 release notes 未通过 GitHub Releases 的 body 字段提供详情。19 个版本更新频率极高（几乎每天一版），说明运行时环境在快速迭代。建议关注 Claude Code 官方 changelog 获取具体变更。

---

## 整合建议优先级

### 1. 必须整合

- **EveryInc/compound-engineering-plugin**: 上游 270+ commits，包含 commands→skills 迁移、plan/review/brainstorm 全面重写、deepen-plan 合并、document-review 重写。这是**近一个月最大的结构性变更**，延迟合并会导致分叉加剧。
  - ⚠️ **合并风险**: 目录结构变更(commands→skills)、技能重写(plan/review)，可能需要大量冲突解决
  - 建议：先 `git merge upstream/main --no-commit` 评估冲突范围

- **obra/superpowers**: Windows 修复、SessionStart hook 行为变更、Copilot CLI 支持、inline self-review。本仓库直接使用这些技能，需要同步以保持兼容。

### 2. 建议整合

- **bmad-code-org/BMAD-METHOD**: checkpoint 技能设计思路、marketplace 元数据格式可参考。无需直接合并代码。

### 3. 可选参考

- **anthropics/claude-code**: 持续关注运行时新功能，但无需直接操作。建议定期检查官方 changelog。

### 4. 暂不需要

- BMAD 的 Junie 平台支持、安装器重构、翻译文档
- superpowers 的 OpenCode 特定修复
