---
name: workflows-zh:compound
description: 将最近解决的问题文档化以沉淀知识
argument-hint: "[可选：修复背景简述]"
---

# /compound

**输出语言：中文。结构与英文版一致。**

并行协调多个子代理，将刚解决的问题文档化。

## 目的

在上下文还新鲜时记录解决方案，在 `docs/solutions/` 中生成结构化文档（包含 YAML frontmatter），便于搜索与复用。使用并行子代理提升效率。

**为什么叫 "compound"？** 每次记录都会让团队知识复利化：第一次解决需要研究；记录后下次只需分钟级查阅。

## 用法

```bash
/workflows:compound                    # 记录最近一次修复
/workflows:compound [brief context]    # 提供额外上下文提示
```

## 执行策略：并行子代理

该命令会并行启动多个专用子代理以最大化效率：

### 1. **上下文分析器**（并行）
   - 提取对话历史
   - 识别问题类型、组件、症状
   - 校验解决方案 schema
   - 输出：YAML frontmatter 骨架

### 2. **解决方案提取器**（并行）
   - 分析调查步骤
   - 找出根因
   - 提取可用解决方案与代码示例
   - 输出：解决方案内容块

### 3. **相关文档查找器**（并行）
   - 搜索 `docs/solutions/` 中相关文档
   - 识别交叉引用与链接
   - 查找相关 GitHub issue
   - 输出：链接与关联关系

### 4. **预防策略师**（并行）
   - 形成预防策略
   - 生成最佳实践建议
   - 如适用生成测试用例
   - 输出：预防/测试内容

### 5. **分类器**（并行）
   - 确定最佳 `docs/solutions/` 分类
   - 校验分类是否符合 schema
   - 给出文件名 slug 建议
   - 输出：最终路径与文件名

### 6. **文档写作者**（并行）
   - 组合完整 Markdown 文件
   - 校验 YAML frontmatter
   - 统一排版以提升可读性
   - 在正确位置创建文件

### 7. **可选：专业代理调用**（文档完成后）
   根据问题类型自动调用：
   - **performance_issue** → `performance-oracle`
   - **security_issue** → `security-sentinel`
   - **database_issue** → `data-integrity-guardian`
   - **test_failure** → `cora-test-reviewer`
   - 任何代码密集问题 → `kieran-rails-reviewer` + `code-simplicity-reviewer`

## 捕获内容

- **问题症状**：具体错误信息与可观察行为
- **调查步骤**：尝试过什么、为什么无效
- **根因分析**：技术原因说明
- **有效解决方案**：步骤化修复与代码示例
- **预防策略**：如何避免再次发生
- **交叉引用**：相关 issue 与文档链接

## 前置条件

<preconditions enforcement="advisory">
  <check condition="problem_solved">
    问题已解决（非进行中）
  </check>
  <check condition="solution_verified">
    解决方案已验证有效
  </check>
  <check condition="non_trivial">
    非简单问题（非拼写错误或明显问题）
  </check>
</preconditions>

## 生成内容

**组织化文档：**

- 文件：`docs/solutions/[category]/[filename].md`

**问题分类自动识别：**

- build-errors/
- test-failures/
- runtime-errors/
- performance-issues/
- database-issues/
- security-issues/
- ui-bugs/
- integration-issues/
- logic-errors/

## 成功输出

```
✓ Parallel documentation generation complete

Primary Subagent Results:
  ✓ Context Analyzer: Identified performance_issue in brief_system
  ✓ Solution Extractor: Extracted 3 code fixes
  ✓ Related Docs Finder: Found 2 related issues
  ✓ Prevention Strategist: Generated test cases
  ✓ Category Classifier: docs/solutions/performance-issues/
  ✓ Documentation Writer: Created complete markdown

Specialized Agent Reviews (Auto-Triggered):
  ✓ performance-oracle: Validated query optimization approach
  ✓ kieran-rails-reviewer: Code examples meet Rails standards
  ✓ code-simplicity-reviewer: Solution is appropriately minimal
  ✓ every-style-editor: Documentation style verified

File created:
- docs/solutions/performance-issues/n-plus-one-brief-generation.md

This documentation will be searchable for future reference when similar
issues occur in the Email Processing or Brief System modules.

What's next?
1. Continue workflow (recommended)
2. Link related documentation
3. Update other references
4. View documentation
5. Other
```

## 复利式知识沉淀

这会形成知识复利系统：

1. 第一次解决 “简报生成的 N+1 查询” → 研究（30 分钟）
2. 记录方案 → docs/solutions/performance-issues/n-plus-one-briefs.md（5 分钟）
3. 再次遇到类似问题 → 快速查阅（2 分钟）
4. 知识复利 → 团队越来越聪明

反馈循环：

```
Build → Test → Find Issue → Research → Improve → Document → Validate → Deploy
    ↑                                                                      ↓
    └──────────────────────────────────────────────────────────────────────┘
```

**每一次工程工作都应让后续更容易，而不是更难。**

## 自动触发

<auto_invoke> <trigger_phrases> - "that worked" - "it's fixed" - "working now" - "problem solved" </trigger_phrases>

<manual_override> 使用 /workflows:compound [context] 立即记录，无需等待自动检测。 </manual_override> </auto_invoke>

## 路由至

`compound-docs` skill

## 可用专业代理

根据问题类型，这些代理可以增强文档：

### 代码质量与评审
- **kieran-rails-reviewer**：审查 Rails 示例是否符合最佳实践
- **code-simplicity-reviewer**：确保解决方案最小且清晰
- **pattern-recognition-specialist**：识别反模式或重复问题

### 特定领域专家
- **performance-oracle**：分析 performance_issue 解决方案
- **security-sentinel**：审查 security_issue 方案
- **cora-test-reviewer**：为预防策略生成测试用例
- **data-integrity-guardian**：审查 database_issue 迁移与查询

### 增强与文档
- **best-practices-researcher**：补充行业最佳实践
- **every-style-editor**：审查文档风格与清晰度
- **framework-docs-researcher**：链接框架/库文档

### 何时调用
- **自动触发**（可选）：文档完成后自动增强
- **手动触发**：用户可在 /workflows:compound 完成后再调用代理深入评审

## 相关命令

- `/research [topic]` - 深度研究（搜索 docs/solutions/ 中的模式）
- `/workflows:plan` - 规划流程（引用已记录的解决方案）
