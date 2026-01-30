---
name: workflows-zh:plan
description: 将需求描述转化为符合项目规范的结构化计划
argument-hint: "[功能描述、Bug 报告或改进想法]"
---

# 创建新功能或 Bug 修复的计划

**输出语言：中文。结构与英文版一致。**

## 引言

**注意：当前年份为 2026。** 在计划日期与检索最新文档时要用到。

将功能描述、Bug 报告或改进想法转化为符合项目规范与最佳实践的结构化 Markdown 计划文件。本命令提供可选的细节层级以匹配你的需求。

## 需求描述

<feature_description> #$ARGUMENTS </feature_description>

**如果上面的需求描述为空，请询问用户：**“你想规划什么？请描述功能、Bug 修复或改进想法。”

在得到清晰的需求描述之前，不要继续。

### 0. 想法澄清

**先检查是否已有头脑风暴输出：**

在提问之前，检查 `docs/brainstorms/` 中最近的头脑风暴文档是否匹配该需求：

```bash
ls -la docs/brainstorms/*.md 2>/dev/null | head -10
```

**相关性标准：** 满足以下条件则视为相关：
- 主题（文件名或 YAML frontmatter）与需求描述语义匹配
- 创建时间在最近 14 天内
- 若有多个候选，使用最新的一个

**如果存在相关头脑风暴：**
1. 阅读该头脑风暴文档
2. 宣布：“发现 [日期] 的头脑风暴：[主题]。将其作为规划上下文。”
3. 提取关键决策、选定方案、未决问题
4. **跳过下面的想法澄清问题** —— 头脑风暴已回答“做什么”
5. 将头脑风暴结论作为研究阶段输入

**如果可能匹配多个头脑风暴：**
使用 **AskUserQuestion 工具**询问用户选择哪一个，或是否直接继续不使用。

**如果没有相关头脑风暴（或不相关），执行想法澄清：**

使用 **AskUserQuestion 工具**进行协作式澄清：

- 一次只问一个问题，逐步理解想法
- 当存在自然选项时优先用选择题
- 关注目的、约束与成功标准
- 直到想法清晰或用户说“继续”为止

**收集研究决策信号。** 澄清过程中记录：

- **用户熟悉度**：是否了解代码库模式？是否指向已有示例？
- **用户意图**：追求速度还是全面？探索还是执行？
- **主题风险**：安全、支付、外部 API 需更谨慎
- **不确定性**：方案是否清晰或仍开放

**可跳过选项：** 若需求描述已足够详细，可询问：
“你的描述已经清楚。要直接进入研究，还是再做补充澄清？”

## 主任务

### 1. 本地研究（总是执行 - 并行）

<thinking>
首先需要理解项目约定、已有模式与已记录的经验。这一步快速且本地化，可帮助判断是否需要外部研究。
</thinking>

并行运行这些代理以收集本地上下文：

- Task repo-research-analyst(feature_description)
- Task learnings-researcher(feature_description)

**重点关注：**
- **仓库研究：** 现有模式、CLAUDE.md 指引、技术熟悉度、模式一致性
- **经验总结：** `docs/solutions/` 中可能适用的解决方案（陷阱、模式、经验教训）

这些结论将影响下一步。

### 1.5. 研究决策

基于第 0 步信号与第 1 步发现，决定是否进行外部研究。

**高风险主题 → 必须研究。** 安全、支付、外部 API、数据隐私等，错过信息代价太高，此项优先级最高。

**本地上下文强 → 可跳过外部研究。** 代码库已有成熟模式、CLAUDE.md 有明确指引、用户目标明确，外部研究价值有限。

**不确定或陌生领域 → 建议研究。** 用户在探索、代码库缺少示例、新技术场景，需要外部视角。

**宣布决策并继续。** 简要说明，用户可随时纠正。

示例：
- “代码库已有成熟模式，本次不做外部研究。”
- “涉及支付流程，先研究最新最佳实践。”

### 1.5b. 外部研究（条件触发）

**仅在 1.5 判断外部研究有价值时执行。**

并行运行这些代理：

- Task best-practices-researcher(feature_description)
- Task framework-docs-researcher(feature_description)

### 1.6. 研究汇总

在研究完成后整合结果：

- 记录仓库研究的相关文件路径（例如 `app/services/example_service.rb:42`）
- **包含 `docs/solutions/` 中的机构性经验**（关键洞见、需避免的陷阱）
- 记录外部文档 URL 与最佳实践（若执行了外部研究）
- 列出发现的相关 issue 或 PR
- 记录 CLAUDE.md 约定

**可选校验：** 简要总结并询问是否遗漏或有误，再进入规划。

### 2. Issue 规划与结构

<thinking>
像产品经理一样思考：怎样让 issue 清晰、可执行？考虑多方视角。
</thinking>

**标题与分类：**

- [ ] 采用常规格式拟定清晰、可检索的标题（如 `feat: Add user authentication`, `fix: Cart total calculation`）
- [ ] 确定问题类型：enhancement、bug、refactor
- [ ] 将标题转为文件名：加上今天日期前缀，去掉前缀冒号，转为 kebab-case，添加 `-plan` 后缀
  - 示例：`feat: Add User Authentication` → `2026-01-21-feat-add-user-authentication-plan.md`
  - 保持描述性（前缀后 3-5 个词）便于检索

**利益相关者分析：**

- [ ] 识别谁会受影响（终端用户、开发者、运维等）
- [ ] 评估实现复杂度与所需专业技能

**内容规划：**

- [ ] 根据复杂度与受众选择合适的细节层级
- [ ] 列出所需的全部章节
- [ ] 收集支撑材料（错误日志、截图、设计稿）
- [ ] 准备代码示例或复现步骤（示例中命名伪文件名）

### 3. SpecFlow 分析

在完成 issue 结构规划后，运行 SpecFlow Analyzer 验证并完善规格：

- Task spec-flow-analyzer(feature_description, research_findings)

**SpecFlow 输出：**

- [ ] 审阅 SpecFlow 结果
- [ ] 补充发现的缺口或边界情况
- [ ] 根据 SpecFlow 更新验收标准

### 4. 选择实现细节层级

选择计划的详尽程度，通常越简单越好。

#### 📄 MINIMAL（快速 Issue）

**适合：** 简单 bug、小改进、明确功能

**包含：**

- 问题陈述或功能描述
- 基本验收标准
- 关键上下文

**结构：**

````markdown
---
title: [Issue Title]
type: [feat|fix|refactor]
date: YYYY-MM-DD
---

# [Issue Title]

[Brief problem/feature description]

## Acceptance Criteria

- [ ] Core requirement 1
- [ ] Core requirement 2

## Context

[Any critical information]

## MVP

### test.rb

```ruby
class Test
  def initialize
    @name = "test"
  end
end
```

## References

- Related issue: #[issue_number]
- Documentation: [relevant_docs_url]
````

#### 📋 MORE（标准 Issue）

**适合：** 多数功能、复杂 bug、团队协作

**包含：**

在 MINIMAL 基础上增加：

- 更详细的背景与动机
- 技术考量
- 成功指标
- 依赖与风险
- 基础实现建议

**结构：**

```markdown
---
title: [Issue Title]
type: [feat|fix|refactor]
date: YYYY-MM-DD
---

# [Issue Title]

## Overview

[Comprehensive description]

## Problem Statement / Motivation

[Why this matters]

## Proposed Solution

[High-level approach]

## Technical Considerations

- Architecture impacts
- Performance implications
- Security considerations

## Acceptance Criteria

- [ ] Detailed requirement 1
- [ ] Detailed requirement 2
- [ ] Testing requirements

## Success Metrics

[How we measure success]

## Dependencies & Risks

[What could block or complicate this]

## References & Research

- Similar implementations: [file_path:line_number]
- Best practices: [documentation_url]
- Related PRs: #[pr_number]
```

#### 📚 A LOT（全面 Issue）

**适合：** 重大功能、架构调整、复杂集成

**包含：**

在 MORE 基础上增加：

- 分阶段的详细实施计划
- 备选方案比较
- 详尽技术规格
- 资源需求与时间线
- 扩展性与未来考虑
- 风险缓解策略
- 文档要求

**结构：**

```markdown
---
title: [Issue Title]
type: [feat|fix|refactor]
date: YYYY-MM-DD
---

# [Issue Title]

## Overview

[Executive summary]

## Problem Statement

[Detailed problem analysis]

## Proposed Solution

[Comprehensive solution design]

## Technical Approach

### Architecture

[Detailed technical design]

### Implementation Phases

#### Phase 1: [Foundation]

- Tasks and deliverables
- Success criteria
- Estimated effort

#### Phase 2: [Core Implementation]

- Tasks and deliverables
- Success criteria
- Estimated effort

#### Phase 3: [Polish & Optimization]

- Tasks and deliverables
- Success criteria
- Estimated effort

## Alternative Approaches Considered

[Other solutions evaluated and why rejected]

## Acceptance Criteria

### Functional Requirements

- [ ] Detailed functional criteria

### Non-Functional Requirements

- [ ] Performance targets
- [ ] Security requirements
- [ ] Accessibility standards

### Quality Gates

- [ ] Test coverage requirements
- [ ] Documentation completeness
- [ ] Code review approval

## Success Metrics

[Detailed KPIs and measurement methods]

## Dependencies & Prerequisites

[Detailed dependency analysis]

## Risk Analysis & Mitigation

[Comprehensive risk assessment]

## Resource Requirements

[Team, time, infrastructure needs]

## Future Considerations

[Extensibility and long-term vision]

## Documentation Plan

[What docs need updating]

## References & Research

### Internal References

- Architecture decisions: [file_path:line_number]
- Similar features: [file_path:line_number]
- Configuration: [file_path:line_number]

### External References

- Framework documentation: [url]
- Best practices guide: [url]
- Industry standards: [url]

### Related Work

- Previous PRs: #[pr_numbers]
- Related issues: #[issue_numbers]
- Design documents: [links]
```

### 5. Issue 创建与格式

<thinking>
应用清晰与可执行的最佳实践，让 issue 易读易扫。
</thinking>

**内容格式：**

- [ ] 使用清晰、分层的标题（##, ###）
- [ ] 代码示例使用三反引号并指定语言高亮
- [ ] UI 相关加入截图/设计稿（拖拽或使用图片托管）
- [ ] 用任务清单 (- [ ]) 以便跟踪
- [ ] 对长日志使用 `<details>` 折叠
- [ ] 使用适当 emoji 便于扫读（🐛 bug、✨ feature、📚 docs、♻️ refactor）

**交叉引用：**

- [ ] 通过 #number 关联 issue/PR
- [ ] 需要时引用 commit SHA
- [ ] 使用 GitHub 永久链接（按 `y`）
- [ ] 需要时 @ 提及相关成员
- [ ] 外部资源用可读文字链接

**代码与示例：**

````markdown
# Good example with syntax highlighting and line references


```ruby
# app/services/user_service.rb:42
def process_user(user)

# Implementation here

end
```

# Collapsible error logs

<details>
<summary>Full error stacktrace</summary>

`Error details here...`

</details>
````

**AI 时代考虑：**

- [ ] 考虑 AI 结对编程加速开发
- [ ] 记录研究中有效的提示词/指令
- [ ] 注明使用了哪些 AI 工具（Claude、Copilot 等）
- [ ] 强调完整测试以匹配快速实现
- [ ] 标注需要人工复核的 AI 生成代码

### 6. 最终检查与提交

**提交前检查清单：**

- [ ] 标题可检索且描述清晰
- [ ] 标签准确
- [ ] 模板章节完整
- [ ] 链接与引用可用
- [ ] 验收标准可度量
- [ ] 示例/待办清单中包含文件名
- [ ] 若涉及模型变更，添加 ERD mermaid 图

## 输出格式

**文件名：** 使用第 2 步中生成的日期 + kebab-case 文件名。

```
docs/plans/YYYY-MM-DD-<type>-<descriptive-name>-plan.md
```

示例：
- ✅ `docs/plans/2026-01-15-feat-user-authentication-flow-plan.md`
- ✅ `docs/plans/2026-02-03-fix-checkout-race-condition-plan.md`
- ✅ `docs/plans/2026-03-10-refactor-api-client-extraction-plan.md`
- ❌ `docs/plans/2026-01-15-feat-thing-plan.md`（不够具体）
- ❌ `docs/plans/2026-01-15-feat-new-feature-plan.md`（过于笼统）
- ❌ `docs/plans/2026-01-15-feat: user auth-plan.md`（非法字符）
- ❌ `docs/plans/feat-user-auth-plan.md`（缺少日期）

## 计划生成后的选项

写完计划文件后，使用 **AskUserQuestion 工具**提示用户：

**问题：**“计划已生成在 `docs/plans/YYYY-MM-DD-<type>-<name>-plan.md`。接下来想做什么？”

**选项：**
1. **打开计划文件** - 在编辑器中打开
2. **运行 `/deepen-plan`** - 用并行研究代理深化每个章节
3. **运行 `/plan_review`** - 获取评审反馈（DHH、Kieran、Simplicity）
4. **开始 `/workflows:work`** - 本地开始执行该计划
5. **在远程开始 `/workflows:work`** - 在 Claude Code Web 中执行（用 `&` 后台运行）
6. **创建 Issue** - 在项目管理工具中创建
7. **简化** - 降低细节层级

根据选择：
- **打开计划文件** → 运行 `open docs/plans/<plan_filename>.md` 用默认编辑器打开
- **`/deepen-plan`** → 以计划路径调用 /deepen-plan
- **`/plan_review`** → 以计划路径调用 /plan_review
- **`/workflows:work`** → 以计划路径调用 /workflows:work
- **`/workflows:work` 远程** → 运行 `/workflows:work docs/plans/<plan_filename>.md &`
- **创建 Issue** → 参见“创建 Issue”章节
- **简化** → 询问“需要简化哪里？”再生成简化版本
- **其他** → 接受自由文本重写或细节修改

在“简化”或“其他”后，循环回到选项，直到用户选择 `/workflows:work` 或 `/plan_review`。

## 创建 Issue

当用户选择“创建 Issue”时，从 CLAUDE.md 中检测项目管理工具：

1. **检查用户 CLAUDE.md 是否设置 tracker**：
   - 查找 `project_tracker: github` 或 `project_tracker: linear`
   - 或在工作流中出现 “GitHub Issues” / “Linear”

2. **若为 GitHub：**

   使用第 2 步的标题与类型（无需再读文件）：

   ```bash
   gh issue create --title "<type>: <title>" --body-file <plan_path>
   ```

3. **若为 Linear：**

   ```bash
   linear issue create --title "<title>" --description "$(cat <plan_path>)"
   ```

4. **若未配置 tracker：**
   询问用户：“你使用哪个项目管理工具？（GitHub/Linear/Other）”
   - 建议在 CLAUDE.md 中添加 `project_tracker: github` 或 `project_tracker: linear`

5. **创建后：**
   - 展示 Issue URL
   - 询问是否继续 `/workflows:work` 或 `/plan_review`

**绝不写代码！只做调研并写计划。**
