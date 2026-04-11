# IDEAS.md — 想法停车场

> 存放所有「已构想但当下未执行」的功能方向。
> 需要时从这里取出，直接 `/ce:brainstorm` 或 `/ce:plan` 继续。
> 完成后打 `[x]`；文件目标保持在 50 行以内。

---

## 工作流体验

- [ ] **`/ce:ideas` 命令**（ideate + next 合并）：统一管理想法停车场，无参数时推荐优先级方向，有参数时生成新方向建议，结束时询问是否存入 IDEAS.md。  
  来源：[2026-04-10-workflow-chain-ideas-resume-requirements.md](docs/brainstorms/2026-04-10-workflow-chain-ideas-resume-requirements.md)

- [ ] **`/ce:resume` 命令**（回归项目入口）：读 git log + IDEAS.md + 最新未完成 plan，输出"上次做了什么 / 有什么在等 / 建议下一步"三段摘要。  
  来源：[2026-04-10-workflow-chain-ideas-resume-requirements.md](docs/brainstorms/2026-04-10-workflow-chain-ideas-resume-requirements.md)

---

## Feature Extensions（部分未完成）

- [ ] **`[R]` 参数接入 `ce:brainstorm`**：brainstorm 开始前自动搜索 docs/solutions/ 历史方案，注入为背景参考。  
  来源：[2026-04-08-feature-extensions-5-improvements-brainstorm.md](docs/brainstorms/2026-04-08-feature-extensions-5-improvements-brainstorm.md) — Task 4

- [ ] **`[R]` 参数 + Intent Gate 接入 `ce:work`**：work 开始前可选触发历史检索；Large 裸提示场景强制 5 问前置澄清。  
  来源：[2026-04-08 plan](docs/plans/2026-04-08-feat-5-feature-extensions-knowledge-research-security-plan.md) — Task 5

- [ ] **Patch Approval 安全控制**：ce:review 整合阶段，所有来自 Codex/Gemini 的建议强制标记 `gated_auto`，禁止自动应用。  
  来源：[2026-04-08 plan](docs/plans/2026-04-08-feat-5-feature-extensions-knowledge-research-security-plan.md) — Task 6-7

---

## 架构方向

- [ ] **Harness Fusion Phase 1：上游合并**（270 commits behind，预计 20-24h）：合并上游 commands→skills 架构迁移，保留中文定制层。  
  来源：[2026-04-07-harness-fusion-brainstorm.md](docs/brainstorms/2026-04-07-harness-fusion-brainstorm.md)

- [ ] **Harness Fusion Phase 2-4：在新架构上集成**：Task Bundle 协议 + Failure FSM + Eval Set 集成到 ce:work 执行链。  
  来源：[2026-04-07-feat-harness-fusion-phase0-plan.md](docs/plans/2026-04-07-feat-harness-fusion-phase0-plan.md) — phase 1-4

---

## Agent 扩展

- [ ] **Slack 研究 Agent**：在 ce:ideate / ce:plan / ce:brainstorm 中集成 Slack 上下文搜索，作为可选的组织知识输入。  
  来源：[2026-04-02-slack-analyst-agent-requirements.md](docs/brainstorms/2026-04-02-slack-analyst-agent-requirements.md) — active

- [ ] **Testing Addressed Gate**：ce:review 中检测「测试是否覆盖了本次改动涉及的场景」，未覆盖时阻止 autofix 通过。  
  来源：[2026-03-29-testing-addressed-gate-requirements.md](docs/brainstorms/2026-03-29-testing-addressed-gate-requirements.md) — active

- [ ] **CLI Agent-Readiness Review Persona**：ce:review 新增条件代理，专项审查 CLI 命令对 AI Agent 调用的友好度。  
  来源：[2026-03-30-cli-readiness-review-persona-requirements.md](docs/brainstorms/2026-03-30-cli-readiness-review-persona-requirements.md) — active

---

## 知识与记忆

- [ ] **自动记忆集成到 `ce:compound`**：compound 执行时自动读取 MEMORY.md，将新发现与已有记忆对比，减少重复记录。  
  来源：[2026-03-18-auto-memory-integration-requirements.md](docs/brainstorms/2026-03-18-auto-memory-integration-requirements.md)

---

## 验证增强

- [ ] **`[V]` Layer 2 通用验证引擎**（含 TEST_COMMAND 检测 + 自动修复循环 + 安全约束 + 设计图对比 + Plan Given/When/Then）：将 Layer 2 从「仅浏览器」扩展为「根据项目类型自动选测试策略」，自动修复最多 3 轮，三层进程清理防护。  
  来源：[2026-04-11-universal-verification-engine-requirements.md](docs/brainstorms/2026-04-11-universal-verification-engine-requirements.md) — 已有需求文档，33 条需求

---

## Party Mode 优化

- [ ] **`[P]` / `[P+]` 分层**：`[P]` 默认 3 个核心视角（用户代言人 + 技术专家 + 魔鬼代言人），`[P+]` 全量 12-14 视角发散。当前 `[P]` 每次都跑 14 视角太重，大多数场景不需要。  
  来源：2026-04-11 用户反馈

---

## 已声明但未实现

- [x] **`ce:brainstorm [C]` Codex 集成**：~~参数表声明但未实现~~ → 已从 git 历史（98030d3）恢复 Phase 2.5 完整实现（v2.49.1）  
  来源：2026-04-11 代码审查发现 → 2026-04-11 修复

---

## 探索中（尚未形成 brainstorm 文档）

- [ ] **IDEAS.md 老化提醒**：条目超过 90 天未动，AI 下次遇到时提示「还需要这个吗？」，防止 IDEAS.md 变成死文档。
- [ ] **`/ce:compound` 自动触发**：`/ce:review` 结束时强制 handoff 到 compound，降低知识沉淀的摩擦。
