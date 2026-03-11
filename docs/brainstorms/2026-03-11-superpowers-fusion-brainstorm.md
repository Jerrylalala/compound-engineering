# Brainstorm: Superpowers 插件融合到 CE

**日期**: 2026-03-11
**参与者**: 老K（架构师）、小美（体验专家）、老张（整合专家）、Codex（超时）
**状态**: 深度对比完成，待进入规划

---

## 我们要做什么

将 [obra/superpowers](https://github.com/obra/superpowers)（77K stars）的精华选择性融合到 compound-engineering-plugin，提升 CE 的整体质量。

## 为什么选择方案 B（深度对比后选择性融合）

三位专家一致认为：SP 的核心工程方法论（TDD、调试、验证）在 CE 中已实现。但方案 B 允许我们逐个对比同名 skill，发现 CE 可能遗漏的微妙细节，取各自精华合并。

## 综合评分对比

| 维度 | CE | SP | 胜者 |
|------|:---:|:---:|:---:|
| 架构设计 | 8/10 | 7/10 | CE |
| 能力覆盖 | 9/10 | 6/10 | CE |
| 工作流成熟度 | 9/10 | 8/10 | CE |
| 可维护性 | 7/10 | 8/10 | SP |
| 上手难度 | 6/10 | 8/10 | SP |
| 功能发现性 | 5/10 | 9/10 | SP |
| 认知负担 | 4/10 | 8/10 | SP |
| 反馈循环 | 8/10 | 9/10 | SP |

**总结**：CE 功能更强，SP 体验更好。

## 已融合历史

| 功能 | 状态 | 来源版本 |
|------|------|---------|
| SessionStart hook async 控制 | ✅ 已融合（曾回归） | b9d80fa |
| Windows hook 路径引号修复 | ✅ 已融合 | v2.43.0 |
| Subagent Worktree 隔离模式 | ✅ 已融合 | v2.40.1 |
| Cursor IDE 支持 | 🔄 计划中（P2） | — |
| 强制 brainstorming 工作流 | 🔄 计划中 | — |

## CE 已有但 SP 没有的能力（无需融合方向）

- 13 个专业代码审查 Agents
- 3 个设计 Agents（Figma）
- 5 个研究 Agents
- MCP Server 集成（Context7）
- 外部 AI 咨询（Codex + Gemini）
- 派对模式
- 上下文保存/加载
- 知识积累系统
- 云存储/图片生成/浏览器自动化

## 需要深度对比的 Skill 清单

### 同名/同功能 Skill 对比任务

| # | CE Skill | SP Skill | 对比重点 |
|---|----------|----------|---------|
| 1 | `test-driven-development` | `test-driven-development` | TDD 强制程度、反模式库、RED-GREEN-REFACTOR 细节 |
| 2 | `systematic-debugging` | `systematic-debugging` | 4 阶段流程差异、根因分析方法 |
| 3 | `brainstorming` | `brainstorming` | 苏格拉底式提问技巧、触发机制 |
| 4 | `create-agent-skills` | `writing-skills` | skill 开发全生命周期框架 |
| 5 | `workflows:plan` (Bite-Sized) | `writing-plans` | 2-5 分钟任务粒度定义差异 |
| 6 | `workflows:work` (Subagent) | `executing-plans` + `dispatching-parallel-agents` | 批量执行 + 并行策略 |
| 7 | `workflows:review` | `requesting-code-review` + `receiving-code-review` | 双向审查流程 |
| 8 | `git-worktree` | `using-git-worktrees` | worktree 管理细节 |
| 9 | （CLAUDE.md 验证铁律） | `verification-before-completion` | 验证完整性 |
| 10 | — | `finishing-a-development-branch` | CE 是否需要独立的分支完成 skill |
| 11 | — | `subagent-driven-development` | CE 已有但实现可能不同 |
| 12 | — | `using-superpowers` | 系统入门引导（CE 可参考） |

### 对比方法

每个 skill 的对比产出：
1. **共有内容**：两边都有且表述相似的部分
2. **CE 独有优势**：CE 有而 SP 没有的精华
3. **SP 独有优势**：SP 有而 CE 缺失或不够深的部分
4. **融合建议**：具体要添加/修改的内容

### 融合优先级

| 优先级 | 对比项 | 预期价值 |
|:---:|--------|---------|
| P1 | #4 writing-skills 框架 | skill 开发效率 +20% |
| P1 | #7 双向审查流程 | 审查质量提升 |
| P1 | #9 验证完整性 | 减少虚假完成声明 |
| P2 | #1 TDD 细节增强 | 测试质量微调 |
| P2 | #10 分支完成 skill | 流程完整性 |
| P2 | #3 brainstorm 触发 | 返工率 -10% |
| P3 | 其余项 | 锦上添花 |

## 风险与注意事项

1. **历史教训**：SessionStart hook 融合曾引发 Windows 回归（v2.43.4），每项融合必须单独验证
2. **渐进式融合**：每项单独提交，方便回滚
3. **先读后改**：必须完整阅读 SP 的 skill 内容后才能决定是否融合
4. **不降级**：如果 CE 现有实现更好，保留 CE 版本
5. **SP 是只读参考**：不引入 SP 的依赖关系

## CE 体验改进建议（三位专家共识）

融合之外，三位专家一致建议 CE 改善认知负担：
1. 简化入口（渐进式披露：新手 5 命令 → 进阶 43 命令）
2. 自动判断修饰符（[P][C][G]）
3. 对外披露区分独立命令数和别名数

## 深度对比结果（2026-03-11 完成）

### 融合价值排行榜

| 排名 | 对比项 | 融合价值 | 核心收益 |
|:---:|--------|:---:|---------|
| 1 | **writing-skills（技能编写框架）** | 9/10 | TDD 应用到 skill 开发、CSO 优化、防合理化技术 |
| 2 | **brainstorming** | 9/10 | 提问方法论、Anti-Patterns、Phase 0 退出快车道 |
| 3 | **代码审查（双向流程）** | 9/10 | "接收审查"指导、禁止表演性同意、YAGNI 检查 |
| 4 | **finishing-branch（新增）** | 9/10 | CE 完全缺失的收尾闭环，填补工作流空缺 |
| 5 | **verification-before-completion** | 9/10 | Agent 委派验证、TDD 红绿循环验证、"精神优先"元规则 |
| 6 | **并行调度** | 9/10 | 独立性判断决策树、prompt 质量模板、整合验证 |
| 7 | **TDD** | 8/10 | "当卡住时"章节、实用性论证、3 条新借口 |
| 8 | **计划编写** | 8/10 | TDD 内嵌任务结构、Plan Header 强制模板 |
| 9 | **调试** | 7/10 | "无根因"分支、协作者信号解读 |
| 10 | **执行流程** | 7/10 | STOP 协议、批评性审查、回退机制 |
| 11 | **git-worktree** | 7/10 | 基线测试验证、目录优先级协议 |
| 12 | **subagent-driven** | 7/10 | 上下文注入优化、全局最终审查、失败任务处理 |
| 13 | **using-superpowers** | 5/10 | Rigid/Flexible 分类、Announce 宣告 |

### SP 给 CE 的三大系统性启发

1. **"防合理化"体系** — 每个纪律性 Skill 都有"借口 vs 现实"表 + Red Flags + "精神优先于字面"元规则
2. **TDD 思维无处不在** — Skill 编写、验证、调试闭环都用 TDD，"一切皆可测试"
3. **显式宣告和元认知** — AI 主动宣告"我正在使用 XX 技能"，提升透明度

### 各 Skill 对比详情摘要

#### 1. TDD（8/10）
- **SP 独有**：「当卡住时」问题-方案表、「TDD IS pragmatic」论证、手动测试批判、3 条额外借口
- **融合重点**：新增"当卡住时"章节、补充 TDD 实用性论证

#### 2. Writing-Skills / 技能编写框架（9/10）
- **SP 独有**：TDD 应用到 skill 开发（RED-GREEN-REFACTOR）、CSO 优化（Description = When to Use, NOT What）、Token 效率（<150 词）、防合理化技术、技能类型分类测试法、STOP 检查点
- **融合重点**：引入 TDD for Skills 框架、CSO 实证案例、完整检查清单

#### 3. 代码审查（9/10）
- **SP 独有**：双向流程（请求+接收）、禁止"表演性同意"、YAGNI 检查、外部审查验证、实施顺序规范
- **融合重点**：新增 `receiving-code-review` skill、审查响应 6 步协议

#### 4. Finishing Branch（9/10，新增）
- **CE 完全缺失**：测试验证 → 4 选项（合并/PR/保留/丢弃）→ 清理 worktree
- **融合重点**：几乎原样引入，填补 /workflows:work 后的收尾空缺

#### 5. Verification-Before-Completion（9/10）
- **SP 独有**：Agent 委派验证模式、TDD 红绿循环验证、Linter≠Compiler、"精神优先于字面"元规则、疲劳状态拦截
- **融合重点**：从 CLAUDE.md 提取为独立 skill，补充 Agent 验证 + 红绿循环

#### 6. 并行调度（9/10）
- **SP 独有**：独立性判断决策树、Agent Prompt 四要素（Focused/Self-contained/Constraints/Specific Output）、整合后验证（conflict check + spot check）
- **融合重点**：在 work.md 增加独立性检查 + 并行 dispatch 路径

#### 7. Brainstorming（9/10）
- **SP 独有**：Phase 0 退出快车道、4 种提问技术、Anti-Patterns 表（6 种）、WHAT vs HOW 边界定义
- **融合重点**：提问方法论 + Anti-Patterns + 设计文档标准模板

#### 8. 计划编写（8/10）
- **SP 独有**：TDD 五步内嵌任务结构、Plan Header 强制模板（Goal/Architecture/Tech Stack）、执行技能引用内嵌
- **融合重点**：Task 结构模板增加 TDD 步骤、Plan 头部增加架构声明

#### 9. 调试（7/10）
- **SP 独有**："无根因"分支处理、"协作者信号"解读表、跨技能引用闭环
- **融合重点**：补充"无根因"章节 + 调试→验证闭环引用

#### 10. 执行流程（7/10）
- **SP 独有**：STOP 协议（明确停止触发条件）、批评性审查（critically review）、回退机制
- **融合重点**：独立 STOP 章节 + 回退协议

#### 11. Git Worktree（7/10）
- **SP 独有**：基线测试验证、目录选择优先级（三级协商）、多语言依赖安装
- **融合重点**：创建后运行基线测试 + 目录协商逻辑

#### 12. Subagent-Driven（7/10）
- **SP 独有**：上下文预注入（No file reading overhead）、全局最终审查、失败任务处理（再派子代理）
- **融合重点**：失败处理规范 + 全局最终审查节点

#### 13. Using-Superpowers / 入门引导（5/10）
- **SP 独有**：Rigid/Flexible 技能分类、统一 Announce 宣告、3 条额外 Red Flags
- **融合重点**：在 CLAUDE.md 补充技能分类标签 + 宣告惯例

### 更新后的融合优先级

| 波次 | 融合项 | 工作量 | 类型 |
|:---:|--------|:---:|------|
| **Wave 1** | finishing-branch（新 skill） | 中 | 新增 |
| **Wave 1** | verification-before-completion（新 skill） | 中 | 新增 |
| **Wave 1** | receiving-code-review（新 skill） | 中 | 新增 |
| **Wave 2** | writing-skills 框架增强 | 高 | 增强 |
| **Wave 2** | brainstorming 增强 | 中 | 增强 |
| **Wave 2** | TDD 增强 | 低 | 增强 |
| **Wave 3** | plan.md 增强（Header + TDD 内嵌） | 中 | 增强 |
| **Wave 3** | work.md 增强（STOP + 并行 + 回退） | 高 | 增强 |
| **Wave 4** | 调试增强 | 低 | 增强 |
| **Wave 4** | git-worktree 增强 | 低 | 增强 |
| **Wave 4** | subagent-driven 增强 | 低 | 增强 |
| **Wave 4** | CLAUDE.md 元认知增强 | 低 | 增强 |

## 下一步

1. **进入 `/workflows:plan`** — 生成详细执行计划（含 4 个 Wave 的任务分解）
2. **按 Wave 顺序执行** — 每个 Wave 单独分支、单独验证、单独提交
3. **更新 CHANGELOG** — 记录每次融合来源

## 参考来源

- [obra/superpowers GitHub](https://github.com/obra/superpowers)
- [Superpowers Plugin Review](https://www.geeky-gadgets.com/claude-code-superpowers-plugin/)
- [How I Ship Big Features with Superpowers](https://richardporter.dev/blog/superpowers-plugin-claude-code-big-features)
- [obra 博客：How I'm using coding agents](https://blog.fsck.com/2025/10/09/superpowers/)
- [Superpowers 中文教程](https://www.cnblogs.com/gyc567/p/19510203)

---

*Generated by Brainstorm Party Mode [P] | 2026-03-11*
