---
date: 2026-03-05
topic: workflow-handoff-improvement
---

# 工作流衔接机制改进

## What We're Building

改进 compound-engineering-plugin 的工作流命令链（brainstorm → plan → work → review → compound → save）之间的衔接机制，解决两个核心问题：

1. **命令断裂** — 多个衔接点缺少 Handoff 逻辑，导致流程中断
2. **AI 跳过关键步骤** — AI 走阻力最小路径，在主对话中直接写代码而非调用 `/workflows:work`

## Why This Approach

### 评估的方案

| 方案 | 描述 | 结论 |
|------|------|------|
| A: 最小修复 | 只修补 5 个断裂点 | 不够 — 不防止未来遗漏 |
| B: 统一协议 | A + 定义 Handoff 规范 | 中等 — 不防止 AI 跳过 |
| C: 智能感知（初版） | A + B + work 回退 + CLAUDE.md 铁律 | 四层防御 — 但 Layer 4 约束力不可靠 |
| **C-Refined: 三层防御 + 命令级约束** | **A + B + work 回退 + 约束下沉到命令文件** | **最终选定** |

### 方案演化过程

1. 初始讨论提出方案 C（四层防御），包含 CLAUDE.md 铁律
2. 派对模式第二轮讨论中发现 Layer 4（CLAUDE.md 铁律）的致命弱点：
   - 长对话中上下文压缩会丢失 CLAUDE.md 内容
   - 自然语言指令是"劝说"而非"强制"，约束力不可靠
   - 可能给人虚假的安全感
3. 关键洞察：**约束应放在行为发生的地方（命令文件内），而非全局配置**
4. 最终方案：Layer 4 降级，约束内嵌到各命令的 Handoff 部分

### 最终方案架构

| 防线 | 机制 | 可靠性 | 解决什么 |
|------|------|:------:|----------|
| Layer 1 | 修补所有断裂点 + 命令级约束 | 高 | 当前断裂 + AI 跳过 |
| Layer 2 | 统一 Handoff 协议 | 中 | 防止未来遗漏 |
| Layer 3 | work 空参数回退 | 高 | 路径传递失败 / 多入口防御 |

**设计原则**：让正确的路径成为最容易的路径，而不是让错误的路径不可能。

## Key Decisions

### 1. plan_review 是最高优先级修复（P0）

**原因**：plan_review 是目前唯一一个"没有出口"的命令（仅 7 行），直接导致了用户遇到的 bug —— 审查后 AI 直接写代码跳过 `/workflows:work`。

**决策**：为 plan_review 增加完整的 Post-Review Options，包含显式调用 `/workflows:work <plan_path>` 的选项，并内嵌约束禁止在主对话直接写代码。

### 2. 约束下沉到命令级别（而非全局铁律）

**原因**：CLAUDE.md 全局铁律在长对话中可能被上下文压缩丢失。命令文件中的约束在 AI 执行该命令时一定会被读到。

**决策**：在每个需要衔接的命令 Handoff 部分添加内嵌约束（如 plan_review 的 "必须通过 /workflows:work 执行"）。

### 3. plan_review Post-Review 设计统一化

**原因**：曾讨论过按审查严重程度给出不同选项，但增加了 AI 判断复杂性。

**决策**：统一为一个选项菜单，让用户自己决定是否修改计划。不做严重程度判断。

### 4. 所有 workflow 命令必须有 Handoff Phase

**原因**：当前衔接机制是各命令各写各的，没有统一规范。

**决策**：在 plugin CLAUDE.md 中定义统一的 Handoff 协议，成本极低但预防价值高。

### 5. work 命令增加空参数回退逻辑

**原因**：用户可能通过多种入口到达 work（Handoff 选项、直接输入、load 恢复），不能假设参数总是正确传递。

**决策**：work 自动扫描 `docs/plans/` 查找未完成计划，与 plan 扫描 `docs/brainstorms/` 保持架构一致。

### 6. load 命令应检测未完成计划

**原因**：跨会话恢复时，用户可能忘记之前在做什么。

**决策**：load 恢复上下文后主动扫描 `docs/plans/` 中的未完成计划并建议继续。

## 具体改动清单

### P0 — plan_review Post-Review Options

**文件**：`plugins/compound-engineering/commands/plan_review.md`

增加 Post-Review Actions，审查完成后呈现统一选项：

```markdown
## Post-Review Actions

审查代理完成后，整合并展示所有审查意见。

使用 AskUserQuestion：

**Question:** "计划审查完成。下一步？"

**Options:**
1. **更新计划后执行** - 根据意见修改计划，然后运行 /workflows:work（推荐）
2. **直接执行 `/workflows:work`** - 按原计划开始实现
3. **仅更新计划** - 修改计划但暂不执行
4. **重新审查** - 重新运行 plan_review

选择 1 时：AI 修改 plan 文件后自动调用 /workflows:work <plan_path>
选择 2 时：直接调用 /workflows:work <plan_path>

⚠️ 约束：选择 1 或 2 时，必须通过 /workflows:work 执行，
不得在主对话中直接编写代码实现计划。
```

### P1 — plan 路径传递 + work Handoff + work 回退

**文件**：`plugins/compound-engineering/commands/workflows/plan.md`

选项 4 改为：
```markdown
**`/workflows:work`** → Call `/workflows:work docs/plans/<plan_filename>.md`
```

**文件**：`plugins/compound-engineering/commands/workflows/work.md`

1. Input Document 部分增加回退逻辑：
```markdown
如果输入为空，自动扫描最近的计划文件：
1. 扫描 docs/plans/*.md，按修改时间排序
2. 检查每个文件是否有未完成任务（含 - [ ]）
3. 唯一匹配 → 提示确认
4. 多个匹配 → AskUserQuestion 选择
5. 无匹配 → 询问用户
```

2. Phase 4 后增加 Phase 5 Handoff：
```markdown
### Phase 5: Handoff

**Question:** "功能已完成并创建了 PR。下一步？"

**Options:**
1. **运行 `/workflows:review`** - 多代理代码审查（推荐）
2. **运行 `/workflows:review [C]`** - Claude + Codex 双重审查
3. **跳过审查** - 不需要额外审查
```

### P2 — 其余断裂点 + Handoff 协议

**文件**：`plugins/compound-engineering/commands/workflows/review.md`

Next Steps 增加：
```markdown
5. **记录解决方案** - 运行 `/workflows:compound`（非 trivial 问题时）
6. **保存上下文** - 运行 `/workflows:save`
```

**文件**：`plugins/compound-engineering/commands/workflows/compound.md`（或对应位置）

选项 1 改为：
```markdown
1. **运行 `/workflows:save`** - 保存项目上下文（推荐）
```

**文件**：`plugins/compound-engineering/CLAUDE.md`

新增 Handoff 协议章节：
```markdown
## Workflow Handoff 协议

所有 commands/workflows/*.md 必须遵循：
1. 最后一个 Phase 必须是 Handoff
2. Handoff 使用 AskUserQuestion 呈现选项
3. 第一个选项是流程中的下一步命令（含完整参数）
4. 必须有"跳过"选项
5. 命令内嵌约束：Handoff 后禁止 AI 自由发挥

检查清单（新增/修改 workflow 命令时验证）：
- [ ] 最后一个 Phase 是否为 Handoff？
- [ ] 选项是否包含下一步命令 + 完整路径？
- [ ] 是否有内嵌行为约束？
```

### P3 — load 检测 + deepen-plan 检查

**文件**：`plugins/compound-engineering/commands/workflows/load.md`

恢复上下文后扫描 `docs/plans/` 查找未完成计划并建议继续。

**文件**：`plugins/compound-engineering/commands/deepen-plan.md`

检查 Post-Enhancement Options 中 `/workflows:work` 是否显式传递文件路径。

## 风险评估

| 风险 | 可能性 | 影响 | 应对 |
|------|:------:|:----:|------|
| 新命令遗漏 Handoff | 中 | 中 | Layer 2 协议 + 检查清单 |
| AI 在自由文本中跳过 work | 低 | 中 | 命令级约束（最佳努力） |
| work 扫描匹配到错误计划 | 低 | 低 | 必须用户确认 |
| load 恢复时计划已过期 | 中 | 低 | 加时间窗口（建议 30 天） |

## Open Questions

- load 扫描未完成计划的时间窗口：14 天（同 brainstorm）还是 30 天（计划可能更长期）？
- deepen-plan 是否需要同样的路径传递修复？（需确认当前实现）
- 是否需要为"如何添加 Workflow 命令"写一个开发者指南？（P3 优先级）

## 外部 AI 咨询结果

| AI | 模型 | 结果 |
|----|------|------|
| Claude 派对模式（第一轮） | opus-4.6 | 提出方案 C 四层防御，优先修复 plan_review |
| Codex（第一次） | gpt-5.3-codex | 回复偏题（hallucination），未提供有效意见 |
| Claude 派对模式（第二轮） | opus-4.6 | 精简为三层防御 + 命令级约束 |
| Codex（第二次） | o4-mini（错误模型） | 模型不支持报错 |
| Codex（第三次） | gpt-5.2-codex（默认） | 成功回复，提出 handoff.json + lint 检查 |
| Codex（第四次） | gpt-5.3-codex（正确） | **成功回复，读取仓库验证全部断裂点** |

### Codex (gpt-5.3-codex) 关键贡献

Codex 主动读取了仓库代码，验证了全部 5 个断裂点（带行号引用），并补充了三个新见解：

1. **$ARGUMENTS 类型判断** — 参数可能是文本描述而非文件路径，work 回退逻辑需先判断
2. **plan_review 增加 "stop" 选项** — 提供显式退出流程的干净出口
3. **双语措辞一致性** — 中英混合仓库需统一 Handoff 描述语言

### 三方对比

| 评估维度 | Claude | Codex (gpt-5.2) | Codex (gpt-5.3) | 共识度 |
|----------|--------|-----------------|-----------------|:------:|
| 三层防御 | 推荐 | 认可 | 认可 + 加 lint | 三方一致 |
| P0: plan_review | 最高优先级 | 最高优先级 | 最高优先级 | 三方一致 |
| 命令级约束 | 核心机制 | necessary | better than global | 三方一致 |
| CI lint 检查 | grep 简化版 | 完整 lint | 应在 P2 做 | 三方一致 |
| handoff.json | 不采纳(KISS) | 建议增加 | 未提及 | 不采纳 |

### 最终采纳清单

| Codex 建议 | 采纳？ | 整合到 |
|-----------|:------:|--------|
| CI lint 脚本 | ✅ | P2 Handoff 协议 |
| $ARGUMENTS 类型判断 | ✅ | P1 work 回退逻辑 |
| plan_review "stop" 选项 | ✅ | P0 plan_review |
| 双语措辞统一 | ✅ | P2 Handoff 协议第 6 条 |
| handoff.json | ❌ | — (Layer 3 已覆盖) |

## Next Steps

→ `/workflows:plan` 将此设计转化为实施计划
