---
type: sync-report
date: 2026-02-04
scan_mode: full
repos_checked: 4
repos_with_updates: 4
items:
  - repo: "EveryInc/compound-engineering-plugin"
    relevance: high
    action: merged
    new_releases: 0
    new_commits: 1
  - repo: "bmad-code-org/BMAD-METHOD"
    relevance: low
    action: skipped
    new_releases: 0
    new_commits: 88
  - repo: "obra/superpowers"
    relevance: medium
    action: referenced
    new_releases: 2
    new_commits: 18
  - repo: "anthropics/claude-code"
    relevance: high
    action: reviewed
    new_releases: 20
    new_commits: 0
---

# 上游同步检测报告

**日期**: 2026-02-04
**检测范围**: 最近 30 天（since 2026-01-05）

## 摘要

| 仓库 | 新 Release | 新 Commits | 相关度 | 建议动作 |
|------|-----------|-----------|--------|----------|
| EveryInc/compound-engineering-plugin | - | 1 | **高** | 需要合并 |
| bmad-code-org/BMAD-METHOD | - | ~88 | 低 | 暂不需要 |
| obra/superpowers | v4.1.0, v4.1.1 | ~18 | **中** | 选择性参考 |
| anthropics/claude-code | v2.0.76 → v2.1.31 (20 releases) | - | **高** | 关注新功能 |

---

## 详细分析

### EveryInc/compound-engineering-plugin

**角色**: parent (git-native) | **upstream remote**: 已配置

#### 相关变更

| 变更 | 类型 | 相关性 | 理由 | 建议 |
|------|------|--------|------|------|
| `9f93f54` Improvement: protect plan files from review deletion (#142) | bug fix | **高** | 本仓库 fork 了 review.md，这个 fix 防止审查过程意外删除 plan 文件，我们也会遇到 | **建议合并** |

**合并方式**: `git merge upstream/main`（仅 1 个 commit，冲突风险低）

---

### bmad-code-org/BMAD-METHOD

**角色**: reference (github-api)

#### Releases

无 30 天内的新 Release。

#### 过滤后 Commits（~88 条，噪音已过滤）

BMAD 过去 30 天非常活跃，处于 **v6.0.0 Beta** 大版本重构阶段。主要变更类别：

| 类别 | 数量 | 代表性变更 | 相关性 |
|------|------|-----------|--------|
| **安装器重构** | ~25 | UnifiedInstaller、多平台安装器标准化 | 低 — 本仓库不使用 BMAD 安装器 |
| **文档重构** | ~15 | Diataxis 原则文档重构、README 重写 | 低 — 文档结构差异太大 |
| **工作流简化** | ~10 | 工作流大幅简化、命令命名标准化 | 低 — 本仓库工作流独立设计 |
| **构建/编译** | ~10 | 模块清单、版本化下载 | 低 — 架构完全不同 |
| **新增功能** | ~8 | cross-file reference validator, social post skill, process control | 低 — 业务领域不同 |
| **Prompt 设计** | ~5 | quick-flow 菜单标准化、editorial review style_guide 输入 | **中** — 可参考菜单 UX 模式 |
| **Bug 修复** | ~15 | 路径修复、placeholder 替换、menu 渲染 | 低 — 具体到 BMAD 架构 |

**总结**: BMAD 正在进行 v6 大版本重构，变更量大但与本仓库几乎无关联。仅 Prompt 设计模式（如菜单标准化）有微弱参考价值。

---

### obra/superpowers

**角色**: reference (github-api)

#### Release Notes

**v4.1.1** (2026-01-23)
- OpenCode 标准化为 `plugins/` 目录
- OpenCode 修复符号链接说明

**v4.1.0** (2026-01-23) ⚠️ Breaking Changes
- OpenCode 切换到原生 skills 系统
- OpenCode 修复 session start 时 agent 重置问题
- OpenCode 修复 Windows 安装问题
- **Claude Code: 修复 Windows hook 执行** — Claude Code 2.1.x 改变了 Windows 上 hook 的执行方式

#### 相关变更

| 变更 | 类型 | 相关性 | 理由 | 建议 |
|------|------|--------|------|------|
| Claude Code 2.1.x Windows hook 修复 (v4.1.0) | fix | **中** | 我们也在 Windows 上运行 Claude Code，hook 执行方式变更可能影响我们 | 参考其解决方案 |
| Subagent worktree 要求 (#382) | docs | **中** | 我们的 `/workflows:work` 也有 subagent 模式，worktree 是良好实践 | 参考其文档 |
| Subagent-driven development: main branch red flag | docs | **中** | 防止在 main 分支上直接执行 subagent 任务，好的安全实践 | 参考其做法 |
| Codex bootstrap subagent 支持 (#361) | feat | 低 | Codex 集成方式不同 | 暂不需要 |
| OpenCode 相关变更 (~15) | fix/feat | 低 | 本仓库不使用 OpenCode | 暂不需要 |

---

### anthropics/claude-code

**角色**: runtime (releases)

#### Release Notes 概要（v2.0.76 → v2.1.31，20 个 Release）

##### 高相关功能

| 版本 | 功能 | 相关性 | 理由 |
|------|------|--------|------|
| **v2.1.20** | Task management 系统（依赖追踪） | **高** | `/workflows:work` 使用 TodoWrite，新 Task 系统可能影响行为 |
| **v2.1.20** | PR review status 显示 | **中** | `/workflows:review` 可利用 |
| **v2.1.19** | Skills 和 slash commands 合并 | **高** | 简化了插件机制，skills 无额外权限时不需审批 |
| **v2.1.19** | `$ARGUMENTS[0]` 索引语法替代 `$ARGUMENTS.0` | **高** | 如有命令使用索引参数需更新语法 |
| **v2.1.16** | VSCode 原生 plugin management | **中** | 影响插件安装体验 |
| **v2.1.14** | Plugin 锁定到 git commit SHA | **中** | 可用于稳定版本控制 |
| **v2.1.9** | `plansDirectory` 设置自定义 plan 文件位置 | **中** | 影响 `/workflows:plan` 输出位置 |
| **v2.1.9** | PreToolUse hooks 返回 `additionalContext` | **中** | Hook 能力增强 |
| **v2.1.3** | 合并 slash commands 和 skills | **高** | 与 v2.1.19 相关的底层变更 |
| **v2.1.2** | 大输出持久化到磁盘而非截断 | **高** | 影响长命令输出的处理方式 |

##### 中相关修复

| 版本 | 修复 | 相关性 | 理由 |
|------|------|--------|------|
| v2.1.31 | PDF 会话锁定修复 | 低 | |
| v2.1.31 | 沙箱模式 "Read-only file system" 误报修复 | **中** | Windows 用户可能遇到 |
| v2.1.30 | PDF pages 参数、OAuth 预配置 | **中** | Read 工具能力增强 |
| v2.1.27 | Windows .bashrc 导致 bash 失败修复 | **中** | Windows 兼容性 |
| v2.1.7 | 安全漏洞：通配符权限绕过 | **高** | 安全相关，需要更新 |
| v2.1.7 | MCP tool search auto mode 默认启用 | **中** | 影响 Context7 MCP |
| v2.1.6 | `/config` 搜索、`/stats` 日期范围 | 低 | UI 改进 |
| v2.1.2 | 命令注入漏洞修复 | **高** | 安全相关 |

##### 低相关变更

大量 UI/UX 改进、IDE 集成、性能优化等日常更新，与插件开发无直接关系。

---

## 整合建议优先级

### 1. 必须整合

- **EveryInc `#142` protect plan files** — 直接 `git merge upstream/main`，1 个 commit，风险低
- **更新 Claude Code 到最新版** — `v2.1.31` 包含安全修复（命令注入、权限绕过）和重要功能（Task 系统、skills 合并）

### 2. 建议整合

- **参考 superpowers 的 subagent worktree 实践** — 在 `/workflows:work` 的 subagent 模式中增加 main 分支保护
- **检查 `$ARGUMENTS[0]` 语法变更** — 确认现有命令是否使用了旧的 `$ARGUMENTS.0` 语法
- **参考 superpowers 的 Windows hook 修复** — 确认我们的 hooks 在 Claude Code 2.1.x 上正常工作

### 3. 可选参考

- **BMAD 的菜单 UX 标准化** — 可参考其快捷键和菜单设计模式
- **superpowers 的 Codex bootstrap subagent** — 未来若增强 Codex 集成可参考
- **Claude Code `plansDirectory` 设置** — 可在文档中提及

### 4. 暂不需要

- BMAD v6.0.0 Beta 安装器重构（架构完全不同）
- BMAD 文档 Diataxis 重构（我们有自己的文档结构）
- superpowers OpenCode 相关变更（不使用 OpenCode）
- Claude Code 大量 UI/UX 细节改进（自动随版本更新生效）
