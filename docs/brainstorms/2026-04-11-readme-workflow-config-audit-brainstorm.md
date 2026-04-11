# README / workflow / 配置准确性审计 Brainstorm

> 审查来源：Claude (4 审查员 + [P] 派对模式) + Codex [C] 交叉验证

## What We're Building

对仓库的**规范入口面**做一次准确性修复 + CI 防回归，而不是全仓库无边界替换。

目标范围：
- 用户首次接触的元数据和入口文档
- 影响安装、发现、调用方式的配置文件
- 防止后续再次漂移的 CI 防线

不做的事：
- 不改历史文档（docs/plans/, docs/solutions/, docs/sync-reports/）
- 不为"自动生成一切"引入重型模板系统

## 全量问题清单（P0-P3 定级）

### P0 — 会直接导致用户操作失败

| # | 问题 | 位置 | 影响 |
|---|------|------|------|
| 1 | 中文文档 70+ 处教用户用不存在的 `/workflows:*` 命令 | INSTALL.md, WORKFLOW-VISUAL.md, CONCEPTS.md, CODEX-WORKFLOWS.md, README.zh-CN.md | 新用户照做 → 命令不存在 |
| 2 | 引用不存在的 `/workflows:load` 和 `/workflows:save` | INSTALL.md L72, L79 | 命令从未存在 |
| 3 | plugin.json + marketplace.json + package.json 的 homepage/repository 指向旧仓库名 | 3 个配置文件 5 处 URL | Marketplace 链接不专业 |

### P1 — 会误导用户对功能的理解

| # | 问题 | 位置 | 影响 |
|---|------|------|------|
| 4 | workflow.html 把 `mode:autofix` 标为"推荐默认"，实际默认是 Interactive | workflow.html review params | 用户预期错误 |
| 5 | workflow.html review 缺 `report-only` 和 `headless` 模式 | workflow.html review params | 重要模式不可见 |
| 6 | 派对模式卡片写"14 个视角"，混淆 `[P]`(3) 和 `[P+]`(12-14) | workflow.html L551 | 核心特性描述不准 |
| 7 | Agent 数量虚高 57→51 | README.md L173, L198 | 对比表失信 |
| 8 | Command 数量虚低 9→15 | plugin.json description | 组件数不准 |

### P2 — 不规范但不影响核心功能

| # | 问题 | 位置 |
|---|------|------|
| 9 | 安装文档旧仓库名 | INSTALL.md (6处), README.zh-CN.md (3处), SYNC.md (1处) |
| 10 | pencil.html 4 个链接指向旧名 | docs/zh-CN/pencil.html |
| 11 | Review 缺 `base:<ref>` 参数 | workflow.html |
| 12 | Work 节点 badges 缺 `[C]` `[G]` | workflow.html |

### P3 — 不改

| # | 问题 | 处置 |
|---|------|------|
| 13 | 历史文档旧仓库名 | 记录当时事实，不改 |
| 14 | Review `[T+]` 未列出 | 等同 `[T]`，不影响功能 |
| 15 | Compound 未提 Full/Lightweight 选择 | 可视化页面不需要 |

## 根因分析

- CI integrity-check 只在 `plugins/compound-engineering/**` 变更时触发，不覆盖 README/docs/marketplace
- 命令从 `/workflows:*` 迁移到 `/ce:*` 时，中文文档未同步更新
- 仓库从 private 改名为 public 时，只更新了 git remote 和主 README，其他文件遗漏

## Key Decisions

- **一个 PR 全修** — P0+P1+P2 + CI 防线，避免漂移窗口
- **GitHub 301 重定向** — 可当兼容层不可当规范答案，配置文件和安装文档必须改
- **CI 需新增 4 类检查** — 组件数量 / URL / 命令名 / 触发范围

## Open Questions

1. `README.zh-CN.md` 是否收敛为与主 README 一致？还是保留为独立中文层说明？
2. `WORKFLOW-VISUAL.md` 是否视为活文档继续维护？还是标为 legacy 并从导航移除？
3. plugin.json description 中的组件数量是否保留（加 CI 校验）还是直接去掉？

## Recommended Approach

方案 C：只修规范入口面 + 加 CI 防线，历史档案不动。

### 修复文件清单

**配置文件（3 个）：**
- `plugins/compound-engineering/.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`
- `package.json`

**主 README（1 个）：**
- `README.md`

**中文文档（7 个）：**
- `README.zh-CN.md`
- `docs/zh-CN/INSTALL.md`
- `docs/zh-CN/CONCEPTS.md`
- `docs/zh-CN/WORKFLOW-VISUAL.md`
- `docs/zh-CN/SYNC.md`
- `docs/zh-CN/workflow.html`
- `docs/zh-CN/pencil.html`

**CI（2 个）：**
- `scripts/check-feature-integrity.sh`
- `.github/workflows/integrity-check.yml`

### 排除清单（不改）

- `docs/plans/**`
- `docs/solutions/**`
- `docs/sync-reports/**`
- `CHANGELOG.md` 中描述历史状态的文字

## Next Step

进入 `/ce:plan` 制定实施计划。
