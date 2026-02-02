# 根因追踪

## 概述

Bug 通常表现在调用栈深处（git init 在错误目录、文件创建在错误位置、数据库用错误路径打开）。你的直觉是在错误出现的地方修复，但那只是治标。

**核心原则：** 沿着调用链向后追踪，直到找到原始触发点，然后在源头修复。

---

## 何时使用

**使用场景：**
- 错误发生在执行深处（不是入口点）
- 堆栈跟踪显示长调用链
- 不清楚无效数据从哪来
- 需要找出哪个测试/代码触发了问题

---

## 追踪过程

### 1. 观察症状

```
Error: git init failed in /Users/user/project/packages/core
```

### 2. 找到直接原因

**什么代码直接导致了这个？**

```typescript
await execFileAsync('git', ['init'], { cwd: projectDir });
```

### 3. 问：谁调用了这里？

```typescript
WorktreeManager.createSessionWorktree(projectDir, sessionId)
  → 被 Session.initializeWorkspace() 调用
  → 被 Session.create() 调用
  → 被测试在 Project.create() 调用
```

### 4. 继续向上追踪

**传递了什么值？**
- `projectDir = ''`（空字符串！）
- 空字符串作为 `cwd` 解析为 `process.cwd()`
- 那是源代码目录！

### 5. 找到原始触发点

**空字符串从哪来？**

```typescript
const context = setupCoreTest(); // 返回 { tempDir: '' }
Project.create('name', context.tempDir); // 在 beforeEach 之前访问！
```

---

## 添加堆栈跟踪

当无法手动追踪时，添加检测代码：

```typescript
// 在有问题的操作之前
async function gitInit(directory: string) {
  const stack = new Error().stack;
  console.error('DEBUG git init:', {
    directory,
    cwd: process.cwd(),
    nodeEnv: process.env.NODE_ENV,
    stack,
  });

  await execFileAsync('git', ['init'], { cwd: directory });
}
```

**关键：** 在测试中使用 `console.error()`（不是 logger——可能不显示）

**运行并捕获：**

```bash
npm test 2>&1 | grep 'DEBUG git init'
```

**分析堆栈跟踪：**
- 寻找测试文件名
- 找到触发调用的行号
- 识别模式（相同测试？相同参数？）

---

## 关键原则

```
找到直接原因 → 能向上追踪一级吗？ → 追踪 → 是源头吗？
                    ↓ 否                    ↓ 是
              绝不只修复症状              在源头修复
                                          ↓
                                  在每层添加验证
                                          ↓
                                     Bug 不可能再发生
```

**绝不只在错误出现的地方修复。** 追溯找到原始触发点。

---

## 堆栈跟踪技巧

- **在测试中：** 使用 `console.error()` 而非 logger——logger 可能被抑制
- **在操作之前：** 在危险操作之前记录，而非失败之后
- **包含上下文：** 目录、cwd、环境变量、时间戳
- **捕获堆栈：** `new Error().stack` 显示完整调用链

---

## 真实示例

**症状：** `.git` 创建在 `packages/core/`（源代码目录）

**追踪链：**
1. `git init` 在 `process.cwd()` 运行 ← 空 cwd 参数
2. WorktreeManager 被传入空 projectDir
3. Session.create() 传递空字符串
4. 测试在 beforeEach 之前访问 `context.tempDir`
5. setupCoreTest() 初始时返回 `{ tempDir: '' }`

**根因：** 顶层变量初始化访问了空值

**修复：** 将 tempDir 改为 getter，如果在 beforeEach 之前访问则抛出异常

**同时添加纵深防御：**
- 第 1 层：Project.create() 验证目录
- 第 2 层：WorkspaceManager 验证非空
- 第 3 层：NODE_ENV 守卫拒绝在 tmpdir 外 git init
- 第 4 层：git init 前的堆栈跟踪日志
