# 测试反模式

**加载此参考文档的时机：** 编写或修改测试、添加 mock、或想要在生产代码中添加仅测试方法时。

## 概述

测试必须验证真实行为，而非 mock 行为。Mock 是隔离的手段，不是被测试的对象。

**核心原则：** 测试代码做了什么，而非 mock 做了什么。

**严格遵循 TDD 可以防止这些反模式。**

---

## 铁律

```
1. 绝不测试 mock 行为
2. 绝不在生产类中添加仅测试方法
3. 绝不在不理解依赖的情况下 mock
```

---

## 反模式 1：测试 Mock 行为

**违规：**
```typescript
// ❌ 差：测试 mock 是否存在
test('渲染侧边栏', () => {
  render(<Page />);
  expect(screen.getByTestId('sidebar-mock')).toBeInTheDocument();
});
```

**为什么错了：**
- 你在验证 mock 工作，而非组件工作
- mock 存在时测试通过，不存在时失败
- 对真实行为什么都没说

**修复：**
```typescript
// ✅ 好：测试真实组件或不要 mock 它
test('渲染侧边栏', () => {
  render(<Page />);  // 不要 mock 侧边栏
  expect(screen.getByRole('navigation')).toBeInTheDocument();
});
```

### 门控函数

```
在断言任何 mock 元素之前：
  问：「我是在测试真实组件行为还是只是 mock 的存在？」

  如果测试 mock 存在：
    停止 - 删除断言或取消 mock 组件

  改为测试真实行为
```

---

## 反模式 2：生产代码中的仅测试方法

**违规：**
```typescript
// ❌ 差：destroy() 只在测试中使用
class Session {
  async destroy() {  // 看起来像生产 API！
    await this._workspaceManager?.destroyWorkspace(this.id);
    // ... 清理
  }
}

// 在测试中
afterEach(() => session.destroy());
```

**为什么错了：**
- 生产类被仅测试代码污染
- 如果在生产中意外调用很危险
- 违反 YAGNI 和关注点分离
- 混淆对象生命周期和实体生命周期

**修复：**
```typescript
// ✅ 好：测试工具处理测试清理
// Session 没有 destroy() - 在生产中是无状态的

// 在 test-utils/ 中
export async function cleanupSession(session: Session) {
  const workspace = session.getWorkspaceInfo();
  if (workspace) {
    await workspaceManager.destroyWorkspace(workspace.id);
  }
}

// 在测试中
afterEach(() => cleanupSession(session));
```

### 门控函数

```
在向生产类添加任何方法之前：
  问：「这只被测试使用吗？」

  如果是：
    停止 - 不要添加它
    把它放在测试工具中

  问：「这个类拥有这个资源的生命周期吗？」

  如果否：
    停止 - 这个方法放错类了
```

---

## 反模式 3：不理解就 Mock

**违规：**
```typescript
// ❌ 差：Mock 破坏了测试逻辑
test('检测重复服务器', () => {
  // Mock 阻止了测试依赖的配置写入！
  vi.mock('ToolCatalog', () => ({
    discoverAndCacheTools: vi.fn().mockResolvedValue(undefined)
  }));

  await addServer(config);
  await addServer(config);  // 应该抛出 - 但不会！
});
```

**为什么错了：**
- 被 mock 的方法有测试依赖的副作用（写配置）
- 为了「安全」过度 mock 破坏了实际行为
- 测试因错误原因通过或莫名其妙失败

**修复：**
```typescript
// ✅ 好：在正确层级 mock
test('检测重复服务器', () => {
  // Mock 慢的部分，保留测试需要的行为
  vi.mock('MCPServerManager'); // 只 mock 慢的服务器启动

  await addServer(config);  // 配置写入
  await addServer(config);  // 检测到重复 ✓
});
```

### 门控函数

```
在 mock 任何方法之前：
  停止 - 还不要 mock

  1. 问：「真实方法有什么副作用？」
  2. 问：「这个测试依赖这些副作用吗？」
  3. 问：「我完全理解这个测试需要什么吗？」

  如果依赖副作用：
    在更低层级 mock（实际的慢/外部操作）
    或使用保留必要行为的测试替身
    不要 mock 测试依赖的高级方法

  如果不确定测试依赖什么：
    首先用真实实现运行测试
    观察实际需要发生什么
    然后在正确层级添加最小 mock

  危险信号：
    - 「我会 mock 这个以防万一」
    - 「这可能慢，最好 mock 它」
    - 不理解依赖链就 mock
```

---

## 反模式 4：不完整的 Mock

**违规：**
```typescript
// ❌ 差：部分 mock - 只有你认为需要的字段
const mockResponse = {
  status: 'success',
  data: { userId: '123', name: 'Alice' }
  // 缺失：下游代码使用的 metadata
};

// 之后：当代码访问 response.metadata.requestId 时崩溃
```

**为什么错了：**
- **部分 mock 隐藏结构假设** - 你只 mock 了你知道的字段
- **下游代码可能依赖你没包含的字段** - 静默失败
- **测试通过但集成失败** - Mock 不完整，真实 API 完整
- **虚假信心** - 测试对真实行为什么都不证明

**铁律：** Mock 现实中存在的完整数据结构，不只是你当前测试使用的字段。

**修复：**
```typescript
// ✅ 好：镜像真实 API 的完整性
const mockResponse = {
  status: 'success',
  data: { userId: '123', name: 'Alice' },
  metadata: { requestId: 'req-789', timestamp: 1234567890 }
  // 真实 API 返回的所有字段
};
```

---

## 反模式 5：测试作为事后想法

**违规：**
```
✅ 实现完成
❌ 没写测试
「准备测试了」
```

**为什么错了：**
- 测试是实现的一部分，不是可选的后续
- TDD 会捕获这个
- 没有测试不能声称完成

**修复：**
```
TDD 循环：
1. 写失败测试
2. 实现让它通过
3. 重构
4. 然后才声称完成
```

---

## 快速参考

| 反模式 | 修复 |
|--------|------|
| 断言 mock 元素 | 测试真实组件或取消 mock |
| 生产中的仅测试方法 | 移到测试工具 |
| 不理解就 mock | 先理解依赖，最小化 mock |
| 不完整的 mock | 完整镜像真实 API |
| 测试作为事后想法 | TDD - 测试优先 |
| 过于复杂的 mock | 考虑集成测试 |

---

## 危险信号

- 断言检查 `*-mock` test ID
- 方法只在测试文件中调用
- Mock 设置 >50% 的测试
- 移除 mock 后测试失败
- 无法解释为什么需要 mock
- 「为了安全」而 mock

---

## 底线

**Mock 是隔离的工具，不是被测试的东西。**

如果 TDD 揭示你在测试 mock 行为，你已经走错了。

修复：测试真实行为或质疑为什么要 mock。
