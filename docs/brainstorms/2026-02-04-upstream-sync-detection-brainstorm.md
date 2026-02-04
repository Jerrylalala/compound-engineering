# Brainstorm: 上游仓库智能同步检测

**日期**: 2026-02-04
**状态**: 已完成
**参与者**: Claude (Opus 4.5) + Codex (GPT-5.2) + Gemini

---

## 我们要构建什么

创建 `/workflows:sync-upstream` 命令，一键检测多个上游仓库最近 30 天的更新，智能分析哪些变更与当前仓库相关，生成结构化报告供用户决策是否整合。

### 默认监控的上游仓库

| 仓库 | 角色 | 关系 |
|------|------|------|
| `EveryInc/compound-engineering-plugin` | 父级基座 | 主上游，已配置 git remote，需要直接 merge |
| `bmad-code-org/BMAD-METHOD` | 方法论参考 | 学习其 Prompt/Skill 设计，不直接合并代码 |
| `obra/superpowers` | 技能参考 | 参考其 Claude Code 增强技能 |
| `anthropics/claude-code` | 运行时环境 | Claude Code 官方更新，关注新功能/API 变化 |

### 仓库可扩展性

支持通过配置文件动态添加/移除监控仓库，无需修改命令源码。

**配置文件**: `docs/sync-reports/upstream-repos.json`

```json
{
  "repos": [
    {
      "repo": "EveryInc/compound-engineering-plugin",
      "role": "parent",
      "strategy": "git-native",
      "remote": "upstream",
      "description": "主上游，需要直接 merge"
    },
    {
      "repo": "bmad-code-org/BMAD-METHOD",
      "role": "reference",
      "strategy": "github-api",
      "description": "方法论参考，学习 Prompt/Skill 设计"
    },
    {
      "repo": "obra/superpowers",
      "role": "reference",
      "strategy": "github-api",
      "description": "技能参考，按需手动迁移"
    },
    {
      "repo": "anthropics/claude-code",
      "role": "runtime",
      "strategy": "releases",
      "description": "运行时环境，关注新功能/API 变化"
    }
  ]
}
```

**角色与策略说明**:

| role | strategy | 行为 |
|------|----------|------|
| `parent` | `git-native` | `git fetch` + `git log`，支持 merge 预览 |
| `reference` | `github-api` | `gh api` 拉取 commits + releases，仅供参考 |
| `runtime` | `releases` | 只关注 GitHub Releases + 版本号变化 |

**扩展操作**：用户只需在 `upstream-repos.json` 中添加一条记录，下次运行 `/workflows:sync-upstream` 即自动纳入检测。命令启动时读取此配置，动态构建检测任务列表。

---

## 为什么选择这个方案

### 决策过程

经过 Claude、Codex (GPT-5.2)、Gemini 三方独立评估，最终方案融合了三方最优见解：

- **Gemini** 提出「角色化混合策略」—— 不同仓库用不同检测手段
- **Codex** 提出「增量缓存」—— `last-sync.json` 记录上次同步点，避免重复分析
- **三方共识**：Release Notes 优先于 raw commits，需要噪音过滤

### 最终方案：角色化混合策略 + 增量缓存 + 三层渐进分析

#### 核心设计：按角色分层处理

| 角色 | 仓库 | 检测策略 | 理由 |
|------|------|----------|------|
| 父级基座 | `EveryInc/compound-engineering-plugin` | Git Native (`git fetch upstream` + `git log`) | 需要直接 merge/cherry-pick 代码 |
| 方法论参考 | `bmad-code-org/BMAD-METHOD` | GitHub API (`gh api`) | 只需学习新 Prompt/Skill，不合并代码 |
| 技能参考 | `obra/superpowers` | GitHub API (`gh api`) | 参考新增技能，按需手动迁移 |
| 运行时环境 | `anthropics/claude-code` | GitHub Releases + NPM Registry | 关注版本发布和新功能，非代码级 |

#### 三层渐进分析

```
第一层：Release Notes（信噪比最高，token 消耗最低）
  ↓ 有 release → 分析 release notes
  ↓ 无 release → 进入第二层

第二层：过滤后的 Commits
  ↓ 过滤规则：忽略 chore/bump/dependabot/merge commits
  ↓ 按目录/scope 分组摘要

第三层：按需深度对比（仅在讨论阶段）
  ↓ 用户标记「感兴趣」的变更
  ↓ gh api 拉取具体文件内容做 diff
```

#### 增量缓存机制

```json
// docs/sync-reports/.last-sync.json
{
  "EveryInc/compound-engineering-plugin": {
    "lastSha": "abc123",
    "lastTag": "v2.39.0",
    "lastSyncDate": "2026-02-04T12:00:00Z"
  },
  "bmad-code-org/BMAD-METHOD": {
    "lastSha": "def456",
    "lastSyncDate": "2026-02-04T12:00:00Z"
  },
  "obra/superpowers": {
    "lastSha": "ghi789",
    "lastSyncDate": "2026-02-04T12:00:00Z"
  },
  "anthropics/claude-code": {
    "lastTag": "v2.1.31",
    "lastSyncDate": "2026-02-04T12:00:00Z"
  }
}
```

每次同步后自动更新，下次只拉增量。

---

## 关键决策

### 1. 命令形式：`/workflows:sync-upstream`

**决定**：作为 workflows 系列的独立命令，与现有工作流解耦。

**理由**：
- 不是每次 `/workflows:load` 都需要检查上游
- 独立命令可按需调用，不增加日常工作流负担
- 符合现有 `workflows:*` 命名惯例

### 2. 检测深度：最近 30 天 + 增量

**决定**：默认检查最近 30 天，但如果有 `last-sync.json`，只检查增量。

**理由**：
- 30 天是合理的「不会错过重要更新」的窗口
- 增量模式避免重复分析已知变更
- 首次运行时无缓存，走 30 天全量

### 3. 自动化程度：报告 + 讨论

**决定**：生成报告后进入交互式讨论，逐项评估是否整合。

**理由**：
- 自动合并风险太高，尤其是跨仓库整合
- 用户需要理解每个变更的背景才能决策
- 讨论阶段可以按需深入（触发第三层分析）

### 4. Claude Code 更新获取方式

**决定**：GitHub Releases 为主，NPM 版本为辅。

**理由**：
- `anthropics/claude-code` 有活跃的 GitHub Releases（已验证，当前 v2.1.31）
- Release Notes 包含结构化的更新说明
- NPM 用于验证版本号和发布时间线

### 5. 噪音过滤策略

**决定**：commit message 过滤 + 目录/scope 分组。

**过滤规则**：
- 忽略：`chore:`, `bump`, `dependabot`, `Merge pull request`（无实质内容的）
- 保留：`feat:`, `fix:`, `refactor:`, `docs:`（有实质内容的）
- 分组：按修改的目录归类（skills/, agents/, commands/, docs/）

---

## 报告输出格式

```markdown
# 上游同步检测报告

**日期**: YYYY-MM-DD
**检测范围**: 最近 30 天 / 自上次同步以来

## 摘要

| 仓库 | 新 Release | 新 Commits | 相关度 | 建议动作 |
|------|-----------|-----------|--------|----------|
| EveryInc/compound-engineering-plugin | v2.40.0 | 12 | 高 | 需要合并 |
| bmad-code-org/BMAD-METHOD | - | 28 | 中 | 选择性参考 |
| obra/superpowers | - | 5 | 低 | 暂不需要 |
| anthropics/claude-code | v2.1.31 | - | 高 | 关注新功能 |

## 详细分析

### EveryInc/compound-engineering-plugin
#### Release Notes
...
#### 相关变更
| 变更 | 类型 | 相关性 | 建议 |
|------|------|--------|------|
| 保护 plan 文件不被删除 (#142) | bug fix | 高 | 建议合并 |
| ... | ... | ... | ... |

### bmad-code-org/BMAD-METHOD
...

### obra/superpowers
...

### anthropics/claude-code
...

## 整合建议优先级

1. **必须整合**：[列表]
2. **建议整合**：[列表]
3. **可选参考**：[列表]
4. **暂不需要**：[列表]
```

---

## 命令执行流程

```
/workflows:sync-upstream [--full]
         │
         ▼
   ┌─────────────┐
   │ 读取缓存     │ docs/sync-reports/.last-sync.json
   │ (有/无)      │
   └──────┬──────┘
          │
          ▼
   ┌─────────────────────────────────────────┐
   │ 并行获取 4 个仓库更新                    │
   │                                         │
   │ EveryInc:  git fetch upstream + git log │
   │ BMAD:      gh api commits + releases    │
   │ superpowers: gh api commits + releases  │
   │ claude-code: gh api releases            │
   └──────┬──────────────────────────────────┘
          │
          ▼
   ┌─────────────┐
   │ 噪音过滤     │ 移除 chore/bump/dependabot
   │ + 分类       │ feat/fix/refactor/docs
   └──────┬──────┘
          │
          ▼
   ┌─────────────┐
   │ AI 分析      │ 相关性判断 + 优先级排序
   │ (三层渐进)   │ Release → Commits → 按需 Diff
   └──────┬──────┘
          │
          ▼
   ┌─────────────┐
   │ 生成报告     │ docs/sync-reports/YYYY-MM-DD-upstream-sync.md
   └──────┬──────┘
          │
          ▼
   ┌─────────────┐
   │ 更新缓存     │ .last-sync.json
   └──────┬──────┘
          │
          ▼
   ┌─────────────┐
   │ 进入讨论     │ 逐项评估是否整合
   │              │ 可触发第三层深度对比
   └─────────────┘
```

---

## 外部 AI 咨询结果

### 三方对比

| 评估维度 | Claude (Opus 4.5) | Codex (GPT-5.2) | Gemini | 共识度 |
|----------|-------------------|------------------|--------|--------|
| 推荐方案 | 方案 A（纯 API + AI） | 方案 A + 缓存 + 规则过滤 | 方案 D：角色化混合策略 | 分歧→融合 |
| 对方案 B | 不推荐 | 不推荐 | 仅对 EveryInc 使用 | 一致否决全面 B |
| 增量追踪 | 未提及 | `last-sync.json` 缓存 | 未明确 | Codex 独特见解 |
| 分析顺序 | commits + releases 并行 | releases 优先 | 三层渐进 | 双方一致：Release 优先 |
| Claude Code 源 | GitHub releases | releases + CHANGELOG | NPM + Release | Gemini 独特见解 |
| 风险提示 | API 调用量 | token 噪音、commit 不规范 | token 爆炸、目录重构 | 三方一致：需过滤噪音 |

### 综合采纳

1. **多方一致**（可信度最高）：
   - 否决全面 Git Fetch（方案 B）
   - Release Notes 优先于 raw commits
   - 需要噪音过滤机制

2. **双方一致**（次优先）：
   - API + AI 分析是核心路径
   - 需要分层/分级处理策略

3. **单方独特见解**（供参考，已采纳）：
   - Codex：`last-sync.json` 增量缓存 ✅ 已采纳
   - Gemini：角色化混合策略 ✅ 已采纳
   - Gemini：NPM 作为 Claude Code 更新源 ✅ 作为辅助采纳

---

## 待确认问题

1. ~~**仓库配置是否可扩展？**~~ ✅ **已确认：是**。通过 `upstream-repos.json` 配置文件支持动态添加/移除仓库。
2. **`--full` 参数** —— 是否需要支持强制全量检查（忽略缓存）？
3. **通知机制** —— 是否需要在发现高优先级更新时通过语音提醒？

---

## 下一步

运行 `/workflows:plan` 进入实现规划阶段。
