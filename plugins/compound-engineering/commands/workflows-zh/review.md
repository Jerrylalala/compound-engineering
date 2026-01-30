---
name: workflows-zh:review
description: 使用多代理分析、超强思考与 worktree 进行彻底代码评审
argument-hint: "[PR 号、GitHub URL、分支名或 latest]"
---

# 评审命令

**输出语言：中文。结构与英文版一致。**

<command_purpose> 使用多代理分析、超强思考与 Git worktree 深度本地检查，进行彻底代码评审。 </command_purpose>

## 引言

<role>资深代码评审架构师，具备安全、性能、架构与质量保障专长</role>

## 前置条件

<requirements>
- Git 仓库，已安装并登录 GitHub CLI（`gh`）
- 干净的 main/master 分支
- 拥有创建 worktree 与访问仓库的权限
- 若评审文档：需要 Markdown 文件路径
</requirements>

## 主任务

### 1. 确定评审目标与环境准备（必须优先）

<review_target> #$ARGUMENTS </review_target>

<thinking>
首先要确定评审目标类型，并准备好代码分析环境。
</thinking>

#### 立即行动：

<task_list>

- [ ] 判断评审类型：PR 号（数字）、GitHub URL、文件路径（.md），或空（当前分支）
- [ ] 检查当前 git 分支
- [ ] 若**已在目标分支**（PR 分支、指定分支或当前分支即目标）→ 直接在当前分支分析
- [ ] 若**不同分支** → 提议使用 worktree：“使用 git-worktree skill 在隔离环境评审”
- [ ] 使用 `gh pr view --json` 获取 PR 标题、内容、文件、关联 issue
- [ ] 配置语言相关分析工具
- [ ] 准备安全扫描环境
- [ ] 确保已切到要评审的分支（用 `gh pr checkout` 或手动切换）

确保代码已准备就绪（worktree 或当前分支）。**仅在此之后**进入下一步。

</task_list>

#### 并行评审代理：

<parallel_tasks>

尽量并行运行以下代理：

1. Task kieran-rails-reviewer(PR content)
2. Task dhh-rails-reviewer(PR title)
3. 若使用 turbo：Task rails-turbo-expert(PR content)
4. Task git-history-analyzer(PR content)
5. Task dependency-detective(PR content)
6. Task pattern-recognition-specialist(PR content)
7. Task architecture-strategist(PR content)
8. Task code-philosopher(PR content)
9. Task security-sentinel(PR content)
10. Task performance-oracle(PR content)
11. Task devops-harmony-analyst(PR content)
12. Task data-integrity-guardian(PR content)
13. Task agent-native-reviewer(PR content) - 验证新功能对 agent 可访问

</parallel_tasks>

#### 条件代理（按需运行）：

<conditional_agents>

仅当 PR 符合条件时运行：

**如果 PR 包含数据库迁移（`db/migrate/*.rb`）或数据回填：**

14. Task data-migration-expert(PR content) - 验证 ID 映射、检查回滚安全
15. Task deployment-verification-agent(PR content) - 生成 Go/No-Go 部署核对清单与 SQL 校验

**何时运行迁移代理：**
- PR 包含 `db/migrate/*.rb`
- PR 修改 ID/枚举/映射列
- PR 包含数据回填脚本或 rake 任务
- PR 改变数据读写方式（如 FK→字符串）
- PR 标题/内容包含：migration、backfill、data transformation、ID mapping

**这些代理会检查：**
- `data-migration-expert`：验证硬编码映射与生产一致性，检查孤儿关联，验证双写模式
- `deployment-verification-agent`：生成可执行的部署前后检查清单、SQL 查询、回滚流程与监控计划

</conditional_agents>

### 4. 超强思考深潜阶段

<ultrathink_instruction> 对以下每个阶段投入最大认知努力。逐步思考，考虑所有角度，质疑假设，并将评审结论综合反馈给用户。 </ultrathink_instruction>

<deliverable>
完整的系统上下文图与组件交互
</deliverable>

#### 阶段 3：利益相关者视角分析

<thinking_prompt> ULTRA-THINK：站在不同利益相关者角度思考，他们关注什么？痛点是什么？ </thinking_prompt>

<stakeholder_perspectives>

1. **开发者视角** <questions>

   - 是否易理解与修改？
   - API 是否直观？
   - 调试是否方便？
   - 可否轻松测试？ </questions>

2. **运维视角** <questions>

   - 如何安全部署？
   - 有哪些指标与日志？
   - 如何排查问题？
   - 资源要求如何？ </questions>

3. **终端用户视角** <questions>

   - 功能是否直观？
   - 错误提示是否友好？
   - 性能是否可接受？
   - 是否解决问题？ </questions>

4. **安全团队视角** <questions>

   - 攻击面是什么？
   - 是否有合规要求？
   - 数据如何保护？
   - 审计能力如何？ </questions>

5. **业务视角** <questions>
   - ROI 如何？
   - 是否存在法律/合规风险？
   - 对上市时间影响？
   - 总拥有成本如何？ </questions> </stakeholder_perspectives>

#### 阶段 4：场景探索

<thinking_prompt> ULTRA-THINK：探索边界与失败场景。在压力下系统如何表现？ </thinking_prompt>

<scenario_checklist>

- [ ] **Happy Path**：正常输入
- [ ] **Invalid Inputs**：空值/异常/格式错误
- [ ] **Boundary Conditions**：最小/最大值、空集合
- [ ] **Concurrent Access**：竞态、死锁
- [ ] **Scale Testing**：10x/100x/1000x 负载
- [ ] **Network Issues**：超时、部分失败
- [ ] **Resource Exhaustion**：内存/磁盘/连接耗尽
- [ ] **Security Attacks**：注入、溢出、DoS
- [ ] **Data Corruption**：部分写入、不一致
- [ ] **Cascading Failures**：下游故障扩散 </scenario_checklist>

### 6. 多角度评审视角

#### 技术卓越角度

- 工程质量评估
- 工程最佳实践
- 技术文档质量
- 工具链与自动化

#### 业务价值角度

- 功能完整性校验
- 性能对用户影响
- 成本收益分析
- 上线时间考量

#### 风险管理角度

- 安全风险评估
- 运营风险评估
- 合规风险验证
- 技术债务评估

#### 团队协作角度

- 评审礼仪
- 知识分享效率
- 协作模式
-  mentoring 机会

### 4. 简化与极简评审

运行 Task code-simplicity-reviewer() 看是否还能简化代码。

### 5. 发现综合与使用 file-todos 创建待办

<critical_requirement> 所有发现必须存入 todos/ 目录，并使用 file-todos skill。不要先询问用户批准，先创建 todo 文件，再汇总反馈。 </critical_requirement>

#### 第 1 步：综合所有发现

<thinking>
汇总所有代理报告，按严重程度与影响分类，去重。
</thinking>

<synthesis_tasks>

- [ ] 汇总所有代理发现
- [ ] 按类型分类：安全、性能、架构、质量等
- [ ] 标注严重等级：🔴 CRITICAL (P1)、🟡 IMPORTANT (P2)、🔵 NICE-TO-HAVE (P3)
- [ ] 去重
- [ ] 估算工作量（Small/Medium/Large）

</synthesis_tasks>

#### 第 2 步：使用 file-todos 创建 todo 文件

<critical_instruction> 使用 file-todos skill 立即为所有发现创建 todo 文件。不要先征求用户批准。并行创建以加速。 </critical_instruction>

**实现选项：**

**方案 A：直接创建文件（更快）**

- 使用 Write 工具直接创建 todo 文件
- 并行生成以加速
- 使用标准模板：`.claude/skills/file-todos/assets/todo-template.md`
- 命名规范：`{issue_id}-pending-{priority}-{description}.md`

**方案 B：并行子代理（推荐规模化）**

当 PR 发现 15+ 条时，使用子代理并行创建：

```bash
# Launch multiple finding-creator agents in parallel
Task() - Create todos for first finding
Task() - Create todos for second finding
Task() - Create todos for third finding
etc. for each finding.
```

子代理可以：

- 并行处理多条发现
- 写出更完整的 todo 细节
- 按严重度组织
- 给出完整的解决方案
- 添加验收标准与工作记录
- 速度更快

**执行策略：**

1. 综合所有发现（按 P1/P2/P3）
2. 按严重度分组
3. 启动 3 个并行子代理（每个严重度一组）
4. 子代理使用 file-todos 创建 todo
5. 汇总结果并向用户报告

**使用 file-todos 的流程：**

1. 针对每条发现：

   - 判断严重度（P1/P2/P3）
   - 写明问题陈述与发现证据
   - 给出 2-3 个解决方案（含优缺点/成本/风险）
   - 估算工作量
   - 添加验收标准与工作日志

2. 使用 file-todos skill：

   ```bash
   skill: file-todos
   ```

   该 skill 提供：

   - 模板：`.claude/skills/file-todos/assets/todo-template.md`
   - 命名规范：`{issue_id}-{status}-{priority}-{description}.md`
   - YAML frontmatter：status、priority、issue_id、tags、dependencies
   - 必要章节：Problem Statement、Findings、Solutions 等

3. 并行创建 todo：

   ```bash
   {next_id}-pending-{priority}-{description}.md
   ```

4. 示例：

   ```
   001-pending-p1-path-traversal-vulnerability.md
   002-pending-p1-api-response-validation.md
   003-pending-p2-concurrency-limit.md
   004-pending-p3-unused-parameter.md
   ```

5. 使用 file-todos 模板结构：`.claude/skills/file-todos/assets/todo-template.md`

**Todo 文件结构（来自模板）：**

每个 todo 必须包含：

- **YAML frontmatter**：status、priority、issue_id、tags、dependencies
- **Problem Statement**：问题是什么、影响是什么
- **Findings**：带证据的发现
- **Proposed Solutions**：2-3 个方案，含优缺点/成本/风险
- **Recommended Action**：初始留空
- **Technical Details**：涉及文件/组件/数据库变更
- **Acceptance Criteria**：可测试的清单
- **Work Log**：工作记录与日期
- **Resources**：PR/Issue/文档链接

**文件命名规范：**

```
{issue_id}-{status}-{priority}-{description}.md

Examples:
- 001-pending-p1-security-vulnerability.md
- 002-pending-p2-performance-optimization.md
- 003-pending-p3-code-cleanup.md
```

**状态值：**

- `pending` - 新发现，待决策
- `ready` - 已批准，可开始
- `complete` - 已完成

**优先级：**

- `p1` - 关键（阻塞合并、安全/数据问题）
- `p2` - 重要（应修复、架构/性能）
- `p3` - 可选（增强、清理）

**标签：** 始终添加 `code-review`，并根据内容添加 `security`、`performance`、`architecture`、`rails`、`quality` 等。

#### 第 3 步：汇总报告

创建所有 todo 后，输出完整汇总：

````markdown
## ✅ Code Review Complete

**Review Target:** PR #XXXX - [PR Title] **Branch:** [branch-name]

### Findings Summary:

- **Total Findings:** [X]
- **🔴 CRITICAL (P1):** [count] - BLOCKS MERGE
- **🟡 IMPORTANT (P2):** [count] - Should Fix
- **🔵 NICE-TO-HAVE (P3):** [count] - Enhancements

### Created Todo Files:

**P1 - Critical (BLOCKS MERGE):**

- `001-pending-p1-{finding}.md` - {description}
- `002-pending-p1-{finding}.md` - {description}

**P2 - Important:**

- `003-pending-p2-{finding}.md` - {description}
- `004-pending-p2-{finding}.md` - {description}

**P3 - Nice-to-Have:**

- `005-pending-p3-{finding}.md` - {description}

### Review Agents Used:

- kieran-rails-reviewer
- security-sentinel
- performance-oracle
- architecture-strategist
- agent-native-reviewer
- [other agents]

### Next Steps:

1. **Address P1 Findings**: CRITICAL - must be fixed before merge

   - Review each P1 todo in detail
   - Implement fixes or request exemption
   - Verify fixes before merging PR

2. **Triage All Todos**:
   ```bash
   ls todos/*-pending-*.md  # View all pending todos
   /triage                  # Use slash command for interactive triage
   ```
````

3. **Work on Approved Todos**:

   ```bash
   /resolve_todo_parallel  # Fix all approved items efficiently
   ```

4. **Track Progress**:
   - Rename file when status changes: pending → ready → complete
   - Update Work Log as you work
   - Commit todos: `git add todos/ && git commit -m "refactor: add code review findings"`

### 严重度说明：

**🔴 P1（关键，阻塞合并）：**

- 安全漏洞
- 数据损坏风险
- 破坏性变更
- 关键架构问题

**🟡 P2（重要，应修复）：**

- 性能问题
- 重大架构问题
- 主要质量问题
- 可靠性问题

**🔵 P3（可选）：**

- 小改进
- 代码清理
- 优化项
- 文档更新

```

### 7. 端到端测试（可选）

<detect_project_type>

**首先，根据 PR 文件检测项目类型：**

| Indicator | Project Type |
|-----------|--------------|
| `*.xcodeproj`, `*.xcworkspace`, `Package.swift` (iOS) | iOS/macOS |
| `Gemfile`, `package.json`, `app/views/*`, `*.html.*` | Web |
| iOS 文件 + Web 文件 | Hybrid（两者都测试） |

</detect_project_type>

<offer_testing>

在输出汇总报告后，按项目类型提供测试选项：

**Web 项目：**
```markdown
**"要运行受影响页面的浏览器测试吗？"**
1. Yes - run `/test-browser`
2. No - skip
```

**iOS 项目：**
```markdown
**"要运行 Xcode 模拟器测试吗？"**
1. Yes - run `/xcode-test`
2. No - skip
```

**Hybrid 项目（如 Rails + Hotwire Native）：**
```markdown
**"要运行端到端测试吗？"**
1. Web only - run `/test-browser`
2. iOS only - run `/xcode-test`
3. Both - run both commands
4. No - skip
```

</offer_testing>

#### 若用户接受 Web 测试：

启用子代理运行浏览器测试（保留主上下文）：

```
Task general-purpose("Run /test-browser for PR #[number]. Test all affected pages, check for console errors, handle failures by creating todos and fixing.")
```

子代理将：
1. 识别受影响页面
2. 逐页访问并截图（使用 Playwright MCP 或 agent-browser）
3. 检查控制台错误
4. 测试关键交互
5. 在 OAuth/邮箱/支付流程处暂停人工确认
6. 若失败创建 P1 todo
7. 修复后重试直到通过

**独立命令：** `/test-browser [PR number]`

#### 若用户接受 iOS 测试：

启用子代理运行 Xcode 测试：

```
Task general-purpose("Run /xcode-test for scheme [name]. Build for simulator, install, launch, take screenshots, check for crashes.")
```

子代理将：
1. 验证 XcodeBuildMCP 安装
2. 发现项目与 scheme
3. 为 iOS Simulator 构建
4. 安装并启动
5. 关键界面截图
6. 捕获控制台错误
7. 在登录/推送/IAP 处暂停人工确认
8. 若失败创建 P1 todo
9. 修复后重试直到通过

**独立命令：** `/xcode-test [scheme]`

### 重要：P1 发现阻塞合并

任何 **🔴 P1（关键）** 发现必须在合并前解决。务必在评审中突出显示，并在合并前处理。
```
