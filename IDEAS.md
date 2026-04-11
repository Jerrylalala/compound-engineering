# IDEAS.md — 想法停车场

> 存放所有「已构想但当下未执行」的功能方向。
> 需要时从这里取出，直接 `/ce:brainstorm` 或 `/ce:plan` 继续。
> 完成后打 `[x]` 或删除；文件目标保持在 50 行以内。

---

## 架构方向

- [ ] **Harness Fusion Phase 1：上游合并**（270 commits behind，预计 20-24h）：合并上游 commands→skills 架构迁移，保留中文定制层。  
  来源：[2026-04-07-harness-fusion-brainstorm.md](docs/brainstorms/2026-04-07-harness-fusion-brainstorm.md)

- [ ] **Harness Fusion Phase 2-4：在新架构上集成**：Task Bundle 协议 + Failure FSM + Eval Set 集成到 ce:work 执行链。  
  来源：[2026-04-07-feat-harness-fusion-phase0-plan.md](docs/plans/2026-04-07-feat-harness-fusion-phase0-plan.md) — phase 1-4

---

## Agent 扩展

- [ ] **Slack 研究 Agent**：在 ce:ideate / ce:plan / ce:brainstorm 中集成 Slack 上下文搜索，作为可选的组织知识输入。  
  来源：[2026-04-02-slack-analyst-agent-requirements.md](docs/brainstorms/2026-04-02-slack-analyst-agent-requirements.md)

- [ ] **Testing Addressed Gate**：ce:review 中检测「测试是否覆盖了本次改动涉及的场景」，未覆盖时阻止 autofix 通过。  
  来源：[2026-03-29-testing-addressed-gate-requirements.md](docs/brainstorms/2026-03-29-testing-addressed-gate-requirements.md)

- [ ] **CLI Agent-Readiness Review Persona**：ce:review 新增条件代理，专项审查 CLI 命令对 AI Agent 调用的友好度。  
  来源：[2026-03-30-cli-readiness-review-persona-requirements.md](docs/brainstorms/2026-03-30-cli-readiness-review-persona-requirements.md)

---

## 知识与记忆

- [ ] **自动记忆集成到 `ce:compound`**：compound 执行时自动读取 MEMORY.md，将新发现与已有记忆对比，减少重复记录。  
  来源：[2026-03-18-auto-memory-integration-requirements.md](docs/brainstorms/2026-03-18-auto-memory-integration-requirements.md)

---

## 探索中（尚未形成 brainstorm 文档）

- [ ] **IDEAS.md 老化提醒**：条目超过 90 天未动，AI 下次遇到时提示「还需要这个吗？」，防止 IDEAS.md 变成死文档。
- [ ] **`/ce:compound` 自动触发**：`/ce:review` 结束时强制 handoff 到 compound，降低知识沉淀的摩擦。
- [ ] **`[R]` + Intent Gate 接入 `ce:work`**：work 开始前可选触发历史检索；Large 裸提示场景强制 5 问前置澄清。  
  来源：[2026-04-08 plan](docs/plans/2026-04-08-feat-5-feature-extensions-knowledge-research-security-plan.md) — Task 5
