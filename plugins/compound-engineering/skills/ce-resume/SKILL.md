---
name: ce:resume
description: "回归项目入口：读取 git log + IDEAS.md + active plan，输出三段摘要，引导下一步"
---

# 回归项目入口

**Note: The current year is 2026.**

`ce:resume` 是间歇性开发者回到项目的起点。运行后你会在 30 秒内知道：
- 上次做了什么
- 有什么在等待
- 建议下一步是什么

然后直接跳入你选择的路径。

## Interaction Method

使用平台的阻塞问答工具（Claude Code 中为 `AskUserQuestion`）。

---

## Execution Flow

### Phase 1: 数据收集（并行读取三个来源）

同时执行以下三个读取操作：

#### 来源 A：git log

```bash
git log --oneline -10
```

- 提取最近 10 条提交
- 识别最后一个「功能性」commit（跳过纯 chore/docs/ci 类型）
- 若命令失败（非 git 仓库）→ 来源 A = 不可用，在摘要中注明「无法读取 git 历史」

#### 来源 B：IDEAS.md

读取项目根目录 `IDEAS.md`：

- 统计未完成条目数量（`- [ ]` 出现次数）
- 提取前 3 条未完成条目的标题（`**[标题]**` 部分）
- 若文件不存在 → 来源 B = 不可用，在摘要中注明「IDEAS.md 不存在，建议运行 /ce:ideas 创建」

#### 来源 C：Active Plans

扫描 `docs/plans/*.md`（若目录不存在则跳过）：

- 读取每个文件的 frontmatter（`---` 之间的 YAML）
- 筛选 `status: active` 的文件
- 按 `date` 字段降序排序，取最新 1-3 个
- 提取每个文件的 `title`（frontmatter 中）和 `date`
- 若目录不存在或无 active plan → 来源 C = 不可用，在摘要中注明「尚无进行中的计划」

---

### Phase 2: 三段摘要输出

基于收集的数据，输出固定格式的三段摘要：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 项目状态摘要
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 上次做了什么

[来源 A 可用时：] 最近的功能性提交：[commit subject]
[附上最近 3-5 条 oneline log，让用户快速定向]

[来源 A 不可用时：] 无法读取 git 历史。

---

## 有什么在等待

[来源 B 可用时：]
💡 IDEAS.md：[N] 个未执行想法
   • [条目 1 标题]
   • [条目 2 标题]
   • [条目 3 标题]
   [若 N > 3，加：] ...等 [N-3] 个更多

[来源 B 不可用时：] IDEAS.md 不存在。

[来源 C 可用时：]
📐 进行中的计划：
   • [plan title 1] ([date])
   • [plan title 2] ([date])

[来源 C 不可用时：] 尚无进行中的计划。

---

## 建议下一步

[推断逻辑：]
- 若有 active plan → 「建议继续 [最新 plan title]，离完成最近」
- 若无 active plan 但 IDEAS.md 有内容 → 「建议从 IDEAS.md 选一个方向，运行 /ce:ideas」
- 若两者都空 → 「项目看起来是全新状态，建议运行 /ce:ideate 或 /ce:ideas 从头探索」

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### Phase 3: Handoff

使用 `AskUserQuestion` 询问用户选择：

> 「好的，你想从哪里开始？」

**动态选项**（根据数据可用性调整）：

- **选项 1（仅当有 active plan 时显示）**：继续上次任务
  `→ Invoke skill compound-engineering:ce-work with args: [最新 active plan 路径]`

- **选项 2（仅当 IDEAS.md 有内容时显示）**：从 IDEAS.md 选一个方向
  `→ Invoke skill compound-engineering:ce-ideas with args: （无参数）`

- **选项 3**：全新开始（从头探索新方向）
  `→ Invoke skill compound-engineering:ce-ideate with args: （无参数）`

- **选项 4**：暂时不操作，我自己来

**Based on selection:**
- 选 1 → 立即运行 `ce-work` 并传入对应 plan 文件路径
- 选 2 → 立即运行 `ce-ideas`（无参数，进入停车场选择路径）
- 选 3 → 立即运行 `ce-ideate`（无参数，open-ended ideation）
- 选 4 → 结束，不执行任何操作
