# 纵深防御验证

## 概述

当你修复一个由无效数据导致的 bug 时，在一个地方添加验证感觉足够了。但那个单一检查可能被不同的代码路径、重构或 mock 绕过。

**核心原则：** 在数据通过的**每一层**都进行验证。让 bug 在结构上不可能发生。

---

## 为什么需要多层

单层验证：「我们修复了 bug」
多层验证：「我们让 bug 变得不可能」

不同层捕获不同情况：
- 入口验证捕获大多数 bug
- 业务逻辑捕获边缘情况
- 环境守卫防止特定上下文的危险
- 调试日志在其他层失败时帮助排查

---

## 四层防御

### 第 1 层：入口点验证

**目的：** 在 API 边界拒绝明显无效的输入

```typescript
function createProject(name: string, workingDirectory: string) {
  if (!workingDirectory || workingDirectory.trim() === '') {
    throw new Error('workingDirectory 不能为空');
  }
  if (!existsSync(workingDirectory)) {
    throw new Error(`workingDirectory 不存在: ${workingDirectory}`);
  }
  if (!statSync(workingDirectory).isDirectory()) {
    throw new Error(`workingDirectory 不是目录: ${workingDirectory}`);
  }
  // ... 继续
}
```

### 第 2 层：业务逻辑验证

**目的：** 确保数据对此操作有意义

```typescript
function initializeWorkspace(projectDir: string, sessionId: string) {
  if (!projectDir) {
    throw new Error('初始化工作区需要 projectDir');
  }
  // ... 继续
}
```

### 第 3 层：环境守卫

**目的：** 在特定上下文中防止危险操作

```typescript
async function gitInit(directory: string) {
  // 在测试中，拒绝在临时目录外 git init
  if (process.env.NODE_ENV === 'test') {
    const normalized = normalize(resolve(directory));
    const tmpDir = normalize(resolve(tmpdir()));

    if (!normalized.startsWith(tmpDir)) {
      throw new Error(
        `拒绝在测试期间在临时目录外 git init: ${directory}`
      );
    }
  }
  // ... 继续
}
```

### 第 4 层：调试检测

**目的：** 为取证捕获上下文

```typescript
async function gitInit(directory: string) {
  const stack = new Error().stack;
  logger.debug('即将 git init', {
    directory,
    cwd: process.cwd(),
    stack,
  });
  // ... 继续
}
```

---

## 应用模式

当你发现 bug 时：

1. **追踪数据流** - 错误值从哪里来？在哪里使用？
2. **映射所有检查点** - 列出数据通过的每个点
3. **在每层添加验证** - 入口、业务、环境、调试
4. **测试每层** - 尝试绕过第 1 层，验证第 2 层能捕获

---

## 关键洞察

所有四层都是必要的。在测试期间，每层都捕获了其他层遗漏的 bug：
- 不同代码路径绕过了入口验证
- Mock 绕过了业务逻辑检查
- 不同平台的边缘情况需要环境守卫
- 调试日志识别了结构性误用

**不要止步于一个验证点。** 在每层都添加检查。
