---
name: workflows:load
description: "Step 0: 加载项目上下文，恢复之前的会话"
argument-hint: "[可选: 自定义加载路径]"
---

# 加载项目上下文

在新会话开始时，加载之前保存的项目上下文，快速恢复工作状态。

## 默认加载位置

```
docs/context/project-context.md
```

## 使用方式

```bash
/workflows:load                           # 从默认位置加载
/workflows:load docs/context/v2.md        # 从指定位置加载
```

## 参数

<load_path> #$ARGUMENTS </load_path>

如果未指定路径，默认从 `docs/context/project-context.md` 加载

---

## 执行流程

### Step 1: 确定加载路径

```
如果 <load_path> 不为空:
    加载路径 = <load_path>
否则:
    加载路径 = "docs/context/project-context.md"
```

### Step 2: 检查文件是否存在

```bash
如果文件不存在:
    提示用户："未找到上下文文件，请先使用 /workflows:save 保存上下文"
    退出
```

### Step 3: 读取并解析文件

读取上下文文件内容，提取关键信息：
- 项目概要
- 技术栈
- 当前进展
- 未解决问题
- 后续计划
- 恢复提示

### Step 4: 输出上下文摘要

向用户展示已加载的上下文摘要，确认理解正确。

---

## 输出格式

```
✅ 项目上下文已加载

📄 来源: {加载路径}
📅 上次更新: {文件中的 updated 字段}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 项目: {项目名称}
🎯 目标: {项目目标}

📊 当前进展:
  ✅ 已完成: {N} 项
  🔄 进行中: {N} 项
  ❌ 待解决: {N} 项

🔧 技术栈: {主要技术}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📌 上次会话摘要:
{session_summary}

🚀 建议的下一步:
{恢复会话提示}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

已准备就绪，请告诉我你想继续做什么？
```

### 未完成计划检测

恢复上下文后，自动扫描是否有未完成的计划：

```bash
ls -la docs/plans/*.md 2>/dev/null | head -10
```

对每个计划文件，检查是否有未完成任务（`- [ ]`）且在 30 天内修改。

**如果发现未完成计划：**
使用 **AskUserQuestion tool**：

**Question:** "发现未完成计划。要继续吗？"

**Options:**
1. **继续执行** - 运行 `/workflows:work <plan_path>`（推荐）
2. **查看计划** - 先查看计划内容再决定
3. **忽略** - 不继续，开始新任务

**如果未发现计划**，继续原有的选项流程。

---

### 原有选项流程

```
选项:
1. 继续上次的工作
2. 查看详细进展
3. 开始新任务
4. 其他
```

---

## 智能检测

如果默认路径不存在，自动搜索可能的上下文文件：

```bash
# 搜索顺序
1. docs/context/project-context.md（默认）
2. docs/context/*.md（其他上下文文件）
3. PROJECT_CONTEXT.md（项目根目录）
4. .context.md（隐藏文件）
```

如果找到多个文件，列出供用户选择：

```
发现多个上下文文件:
  1. docs/context/project-context.md (2024-01-15)
  2. docs/context/feature-auth.md (2024-01-14)

请选择要加载的文件 (输入编号或路径):
```

---

## 文件不存在时的处理

```
⚠️ 未找到项目上下文文件

默认路径 docs/context/project-context.md 不存在。

可能的原因:
1. 这是一个新项目，还没有保存过上下文
2. 上下文文件保存在其他位置

建议操作:
- 如果是新项目，直接开始工作，结束前使用 /workflows:save 保存
- 如果有其他上下文文件，使用 /workflows:load [路径] 指定加载
- 如果需要从头开始，使用 /workflows:brainstorm 或 /workflows:plan
```

---

## 与工作流集成

加载上下文后，可以无缝衔接工作流：

```
/workflows:load
    ↓
（上下文已恢复）
    ↓
/workflows:work [继续之前的计划]
    或
/workflows:plan [开始新功能]
```

---

## 适用场景

- 新会话开始，需要恢复之前的工作状态
- 隔天继续开发同一个功能
- 团队成员接手项目，需要了解上下文
- 跨设备继续工作

## 相关命令

- `/workflows:save` - 保存项目上下文
- `/workflows:brainstorm` - 头脑风暴（新功能）
- `/workflows:plan` - 创建工作计划
- `/workflows:work` - 执行工作计划
