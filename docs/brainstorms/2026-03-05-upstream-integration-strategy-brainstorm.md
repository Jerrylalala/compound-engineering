---
date: 2026-03-05
topic: upstream-integration-strategy
---

# 上游仓库整合策略

## What We're Building

建立可持续的多上游整合机制，将 4 个上游仓库（EveryInc/compound-engineering-plugin、BMAD-METHOD、superpowers、claude-code）的功能整合到私有 fork，同时保护 33 个自定义文件和中文化层。

## Why This Approach

### 问题现状

**当前状态**：
- 私有 fork 基于 EveryInc/compound-engineering-plugin，距上次同步约 1 个月
- 33 个自定义文件（中文文档、Gemini/Codex 集成、自动化脚本）面临删除风险
- upstream remote 已配置（2026-03-05）✅
- 4 个上游有不同角色和整合需求

**上游变更摘要**（最近 30 天）：
| 仓库 | 关键变更 | 相关度 |
|------|----------|--------|
| EveryInc/compound-engineering-plugin | workflows:* → ce:* 重命名（破坏性） | 高 |
| bmad-code-org/BMAD-METHOD | brainstorming no-overwrite 修复、root cause analysis skill | 中 |
| obra/superpowers | Cursor 支持、Windows 修复、强制工作流 | 高 |
| anthropics/claude-code | 主要是 chore commits | 低 |

### 评估的方案

| 方案 | 描述 | 结论 |
|------|------|------|
| A: 直接 git merge | 一次性合并 upstream/main | ❌ 不可行 — 33 个文件删除风险 |
| B: 永久 cherry-pick | 只挑选关键 commits | ⚠️ 不可持续 — 失去冲突可见性 |
| C: 分阶段混合策略 | 立即 cherry-pick + 短期准备 + 中期 merge | ✅ Party Mode 共识 |
| **D: 双轨混合策略** | **发布轨 + 演练轨 + 保护层** | **✅ Codex 推荐（最优）** |

### 最终方案：双轨混合策略

**核心理念**（Codex 改进版）：
1. **发布轨**：只进可控改动，按批次 cherry-pick/手工移植，保证随时可发布
2. **演练轨**：固定周期做 upstream/main dry-run merge（不直接发布），专门统计冲突和删除风险
3. **保护层**：先建立"33 个自定义文件保护清单 + 冲突检测脚本 + 冒烟测试"，再做任何上游整合

**优势**：
- 比"直接 merge"安全（保护层 + 演练轨预警）
- 比"永久 cherry-pick"可持续（演练轨保持冲突可见性）
- 比"分阶段策略"更明确（双轨分离关注点）

## Key Decisions

### 1. 4 个上游的角色定位（三方一致）

| 仓库 | 角色 | 整合策略 | 优先级 |
|------|------|----------|--------|
| EveryInc/compound-engineering-plugin | **parent** | 演练轨 merge + 发布轨 selective pick | P0 |
| anthropics/claude-code | **runtime** | 仅 runtime 兼容必需的 chore | P1 |
| obra/superpowers | **reference** | 手工移植或 patch-queue | P2 |
| bmad-code-org/BMAD-METHOD | **reference** | 手工移植或 patch-queue | P3 |

**关键洞察**（Codex）：只把 EveryInc 当真正 upstream；其余 3 个仓库按"参考补丁源"处理。

### 2. workflows:* 重命名处理（Codex 建议采纳）

**决策**：内部跟随上游 `ce:*`，外部保留 `workflows:*` 兼容别名

**理由**：
- 只保留 `workflows:*` → 每次同步都反向改名（维护负担）
- 完全切 `ce:*` → 伤现有用户习惯（用户体验）
- **双命名兼容** → 平衡长期维护成本和用户体验

**实施**：
- 内部命令文件改为 `ce:*`
- 创建 `workflows:*` 别名命令（指向 `ce:*`）
- 文档注明对应关系
- 设明确策略：长期兼容或版本化退场（不悬而未决）

### 3. 保护层优先建立（Codex 强调）

**在任何上游整合前**，先建立：
1. **33 文件清单**：`docs/fork-ownership.md`（路径归属 + 合并策略）
2. **删除检测脚本**：`scripts/detect-upstream-conflicts.ps1`
3. **冒烟测试**：
   - 静态契约：命令名、目录结构、关键文件存在性
   - 行为冒烟：brainstorming no-overwrite、Windows path、Cursor 流程
   - 回归快照：关键 Markdown/配置输出 snapshot diff
   - 端到端最小链路：`bun test` + 1 条真实工作流脚本跑通

### 4. 整合清单（深度分析后扩展为 10 项）

**用户决策**：全部整合，要最优解。不只是修复 bug，还要整合有价值的提示词设计。

#### P0 — 直接影响可靠性

| 修复 | 来源 | 整合方式 | 理由 |
|------|------|----------|------|
| SessionStart hook async→false | superpowers (4c83681) | 单字段修改 | 防止 context 注入竞态条件，我们踩过此坑 |
| Windows hook 路径引号修复 | superpowers (31bbbe2) | 手工移植 | 我们在 Windows 11 环境，直接受益 |
| **跨平台 AskUserQuestion 回退** | **EveryInc (9a16de4)** | **手工移植 preamble** | **非 Claude 环境（Codex/Gemini）下 AskUserQuestion 不可用时的降级方案，直接影响我们的多 AI 集成** |

#### P1 — 功能增强

| 修复 | 来源 | 整合方式 | 理由 |
|------|------|----------|------|
| brainstorming no-overwrite | BMAD-METHOD (17fe438) | 手工移植 | 防止 workflow 静默覆盖已有产出物 |
| Edge-Case-Hunter 审查任务 | BMAD-METHOD (43cfc01) | 提取核心 prompt → review 可选步骤 | 增强 /workflows:review 的边缘案例检测 |
| Findings-Triage skill | BMAD-METHOD (7ece8b0) | 中文化移植到 skills-custom/ | 结构化 review 产出 |
| **ce:plan brainstorm 集成增强** | **EveryInc (0e32da2)** | **合并上游 7 点指令到我们的 plan.md** | **上游加强了 brainstorm→plan 信息传递：强制引用决策来源、禁止遗漏内容、link back to source。我们当前只有 5 点，缺少 3 个关键指令** |
| **review.md 渲染修复** | **EveryInc (b817b9e)** | **对比合并** | **修复 review 命令的格式渲染问题，我们 fork 的版本可能有同样问题** |

#### P2 — 能力扩展

| 修复 | 来源 | 整合方式 | 理由 |
|------|------|----------|------|
| Review-Prompt skill | BMAD-METHOD (9536e1e) | 中文化移植到 skills-custom/ | 我们仓库本身就是 prompt 集合，自审能力高价值 |
| Root cause analysis skill | BMAD-METHOD (2f484f1) | 中文化移植到 skills-custom/ | 补充 debugging 工作流 |
| Cursor 支持 | superpowers (772ec9f) | 添加 .cursor-plugin/ + 双格式 hook | 扩展 IDE 覆盖范围 |
| **Proof 协作文档技能** | **EveryInc (30d3327)** | **移植 skills/proof/SKILL.md + Handoff 可选项** | **通过 Proof Web API 创建/编辑/分享 Markdown 文档，brainstorm 和 plan 的 Handoff 中新增"Share to Proof"选项** |

#### P3 — 参考借鉴

| 修复 | 来源 | 整合方式 | 理由 |
|------|------|----------|------|
| Quick-Dev2 统一工作流 | BMAD-METHOD (35a7f10) | 仅参考设计理念 | 与现有结构冲突大，但步骤路由逻辑可借鉴 |
| 强制 brainstorming 工作流 | superpowers (7f2ee61) | 理念写入现有 skill | 与 Handoff 协议理念一致 |
| **多 IDE 同步基础设施** | **EveryInc (168c946, e06e5b8)** | **仅参考架构** | **Qwen/Kiro/Windsurf/OpenClaw 同步 + 自动检测安装工具 + `--target all`，主要是 CLI 层面，不涉及提示词** |
| **Qwen Code 支持** | **EveryInc (e1d5bde)** | **仅参考** | **claude-to-qwen 转换器，支持嵌套命令（workflows:plan），可参考其转换逻辑** |

**注意**：非 parent 的用手工移植优先（避免 cherry-pick 语义漂移）

### 4.1 EveryInc 提示词深度分析（upstream/main 已拉取）

**分析基础**：已通过 `git fetch upstream main` 拉取 50+ commits，以下为逐 commit 分析结果。

#### ce:plan brainstorm 集成指令对比

| 指令 | 我们的 plan.md | 上游 ce:plan.md | 差距 |
|------|---------------|-----------------|------|
| 读取 brainstorm | ✅ 有 | ✅ 有 | — |
| 提取决策和方案 | ✅ 有 | ✅ 有 | — |
| 跳过 idea refinement | ✅ 有 | ✅ 有 | — |
| brainstorm 作为主要输入 | ✅ 有 | ✅ 有 | — |
| 标注开放问题 | ✅ 有 | ✅ 有 | — |
| **brainstorm 是 origin document** | ❌ 缺失 | ✅ 有 `Critical:` | **需补充** |
| **禁止遗漏 brainstorm 内容** | ❌ 缺失 | ✅ 有 `Do not omit` | **需补充** |
| **link back to source** | ❌ 缺失 | ✅ 有 `(see brainstorm:...)` | **需补充** |

#### 上游 ce:brainstorm vs 我们的 workflows:brainstorm

上游的 `ce:brainstorm` 是**精简版**（145 行 vs 我们的 293 行），移除了：
- Party Mode `[P]` 支持
- Codex `[C]` / Gemini `[G]` 外部咨询
- 详细的参数解析逻辑

**结论**：上游的 ce:brainstorm 是功能退化版，我们的版本更强。不需要从上游合并 brainstorm 提示词。

#### 上游 workflows:* 弃用包装器模式

```yaml
# 上游的弃用包装器格式
---
name: workflows:brainstorm
description: "[DEPRECATED] Use /ce:brainstorm instead"
disable-model-invocation: true
---
NOTE: /workflows:brainstorm is deprecated. Please use /ce:brainstorm instead.
/ce:brainstorm $ARGUMENTS
```

**关键发现**：上游使用 `disable-model-invocation: true` 标记弃用命令，使其仅作为转发器而不被 AI 自动调用。

**我们的双命名策略应反向使用此模式**：
- `commands/ce/*.md` → 完整命令（`disable-model-invocation: true`，因为我们保留 `workflows:*` 为主命令）
- `commands/workflows/*.md` → 保持完整内容（不弃用，不降级）
- 或者更简洁：直接在 `ce:*` 中 forward 到 `workflows:*`

### 5. 可直接复用的设计模式（深度分析提取）

**模式一：列目录不读内容（Context 节约）**
```
检测已有会话时：只 list 文件名（不 read 内容）→ 展示给用户确认 → 用户选择后才 read
```

**模式二：工作流变量统一求值**
```
workflow 入口处一次性求值 output_file = "session-{{date}}-{{time}}.md"
所有步骤引用 {output_file}，避免跨步骤文件名不一致
```

**模式三：双格式 Hook 输出（跨 IDE 兼容）**
```json
{
  "additional_context": "...",       // Cursor 格式
  "hookSpecificOutput": {
    "additionalContext": "..."        // Claude Code 格式
  }
}
```

**模式四：强制用户确认（防止自动覆盖）**
```
任何"可能覆盖现有产出"的操作前：
1. 检测存在性（不读内容）
2. 展示选项 [1]续接 [2]新建 [3]查看全部
3. 等待用户明确选择
禁止：检测到存在就自动续接
```

### 5. 自动化工具选择（Codex 建议）

**不适合**：`git-subtree/subrepo/repo`（不适合"同一代码树多来源语义整合"）

**推荐**：
- `git rerere`：自动记忆冲突解决方案
- `git range-diff`：对比 commit 范围差异
- 自定义冲突扫描脚本
- `.gitattributes` 受保护路径清单（对部分路径 `merge=ours`）

### 6. 固定同步节奏（Codex 建议）

- **每 2 周**：小同步（cherry-pick 关键修复）
- **每月一次**：dry-run merge 报告（演练轨）
- **每季度**：完整整合评审（发布轨）

## 具体改动清单

### 阶段 0：环境准备（本周）

1. **配置 upstream remote**（仅 EveryInc）
   ```bash
   git remote add upstream https://github.com/EveryInc/compound-engineering-plugin.git
   git fetch upstream
   git tag baseline-2026-03-05 HEAD  # 打基线 tag
   ```

2. **建立保护层**
   - 创建 `docs/fork-ownership.md`（33 文件清单）
   - 创建 `scripts/detect-upstream-conflicts.ps1`
   - 创建 `scripts/smoke-test.ps1`（冒烟测试）
   - 配置 `.gitattributes`（受保护路径 `merge=ours`）

3. **建立演练轨分支**
   ```bash
   git checkout -b upstream-integration-2026-03
   git merge --no-commit --no-ff upstream/main  # dry-run
   # 生成冲突报告，不提交
   git merge --abort
   git checkout main
   ```

### 阶段 1：关键修复整合（第 1-2 周）

开 `sync/critical-2026-03` 分支，手工移植 4 个关键修复：

1. **brainstorming no-overwrite**（BMAD-METHOD）
   - 参考 commit: 17fe438
   - 修改 `plugins/compound-engineering/commands/workflows/brainstorm.md`
   - 添加检测旧 brainstorm 逻辑

2. **Windows 路径修复**（superpowers）
   - 参考 commit: 31bbbe2
   - 修改相关 hook 脚本
   - 测试 Windows 环境

3. **Cursor 支持**（superpowers）
   - 参考 commit: 772ec9f
   - 添加 Cursor plugin manifest
   - 添加 hook 兼容性

4. **Root cause analysis skill**（BMAD-METHOD）
   - 参考 commit: 2f484f1
   - 移植到 `skills-custom/root-cause-analysis/`

**验证**：运行 `scripts/smoke-test.ps1` 确认无回归

### 阶段 2：双命名兼容（第 3 周）

1. **内部改为 ce:***
   - 重命名 `commands/workflows/*.md` 中的 `name: workflows:*` → `name: ce:*`
   - 更新所有内部引用

2. **创建 workflows:* 别名**
   - 在 `commands/` 创建 `workflows-*.md` 别名文件
   - 每个别名指向对应的 `ce:*` 命令
   - 添加弃用警告（可选）

3. **更新文档**
   - `README.md` 添加命令映射表
   - `docs/zh-CN/INSTALL.md` 注明双命名
   - `CHANGELOG.md` 记录此变更

### 阶段 3：演练轨定期运行（每月）

1. **创建演练分支**
   ```bash
   git checkout -b upstream-integration-$(date +%Y-%m)
   git merge --no-commit --no-ff upstream/main
   ```

2. **生成冲突报告**
   - 运行 `scripts/detect-upstream-conflicts.ps1`
   - 记录到 `docs/sync-reports/YYYY-MM-upstream-conflicts.md`
   - 分析删除风险、冲突文件、新增功能

3. **评审并决策**
   - 哪些变更值得整合到发布轨
   - 哪些冲突需要提前准备解决方案
   - 哪些上游删除需要 fork 保留

4. **清理演练分支**
   ```bash
   git merge --abort
   git checkout main
   git branch -D upstream-integration-$(date +%Y-%m)
   ```

## 外部 AI 咨询结果

| 评估维度 | Claude Party Mode | Codex (gpt-5.3) | 共识度 |
|----------|-------------------|-----------------|:------:|
| 核心策略 | 分阶段混合策略 | 双轨混合策略 | 高度一致 |
| workflows 重命名 | 保持不变（用户习惯优先） | 双命名兼容（内部 ce:*，外部 workflows:*） | **采纳 Codex** |
| 4 个上游角色 | 未明确区分 | 只把 EveryInc 当真正 upstream | **采纳 Codex** |
| 保护层优先级 | 短期准备 | 任何整合前必须建立 | **采纳 Codex** |
| 自动化工具 | 未提及 | git rerere + range-diff + 自定义脚本 | **采纳 Codex** |
| 同步节奏 | 未明确 | 每 2 周小同步 + 每月 dry-run | **采纳 Codex** |
| 测试策略 | "测试即文档" | 四层测试（静态契约 + 行为冒烟 + 回归快照 + 端到端） | **采纳 Codex** |

**综合建议**：
1. **核心架构**：采用 Codex 的双轨混合策略（更清晰的关注点分离）
2. **workflows 重命名**：采用 Codex 的双命名兼容（平衡长期维护和用户体验）
3. **保护层**：采用 Codex 的优先级（先建立再整合）
4. **同步节奏**：采用 Codex 的固定节奏（可预测、可持续）

## Open Questions

1. **workflows:* 兼容层的退场策略**：长期兼容 vs 版本化退场（如 v3.x 兼容，v4.0 强制切换）？
2. **演练轨的频率**：每月一次是否足够？是否需要在重大上游变更时额外触发？
3. **33 文件清单的维护**：谁负责更新？如何确保不遗漏新增的自定义文件？
4. **Gemini/Codex 集成的模块化**：是否需要重构为独立插件以减少核心路径改动？
5. **中文化层的维护策略**：上游英文文档更新时，如何同步更新中文版本？

## Potential Risks（Codex 提醒）

| 风险 | 影响 | 缓解方案 |
|------|------|----------|
| 上游重命名导致重复冲突 | 中 | 双命名兼容 + 演练轨预警 |
| "chore" 里混入行为变更 | 中 | 演练轨逐 commit 审查 |
| 非 parent commit cherry-pick 语义漂移 | 高 | 手工移植优先 |
| 自定义文件被删"无声回退" | 高 | 保护层 + 删除检测脚本 |
| Windows 修复只在 PowerShell 生效 | 低 | 测试覆盖 bash/WSL |
| 文档和命令别名不同步 | 中 | 自动化检查脚本 |

## Next Steps

→ `/workflows:plan` 将此设计转化为实施计划
