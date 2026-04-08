---
id: "fn-03"
name: "React useEffect 缺少 AbortController 导致竞态"
dimension: false-negative
difficulty: hard
target_agents:
  - julik-frontend-races-reviewer
target_tier: analytical
tags: [react, race-condition, useEffect, abort]
fixture: "race-condition.tsx"
context: ""
expected_finding_count: "1-2"
expected_conclusion: finding
expected_types: [risk]
must_not_contain: []
scoring:
  - metric: race_condition_identified
    pass_if: "== true"
  - metric: cleanup_suggestion
    pass_if: "mentions AbortController or cleanup"
---

## 场景描述

React 组件在 `useEffect` 中执行异步 fetch，但：
1. 没有 AbortController
2. 没有 cleanup 函数
3. fetch 回调中直接调用 `setState`

当用户快速导航离开此页面时，已卸载组件的 setState 调用会导致内存泄漏和 React 警告。更严重的是，如果两次 fetch 的响应顺序与发起顺序不同，UI 会显示过期数据。

## 输入说明

`fixtures/race-condition.tsx` 包含一个看似正常的 React 组件：

```tsx
function UserProfile({ userId }) {
  const [user, setUser] = useState(null);
  
  useEffect(() => {
    fetch(`/api/users/${userId}`)
      .then(res => res.json())
      .then(data => setUser(data));
  }, [userId]);
  
  return user ? <div>{user.name}</div> : <Loading />;
}
```

## 预期行为

- 识别出缺少 AbortController / cleanup 的竞态风险
- 指出快速切换 userId 时可能显示过期数据
- 建议添加 AbortController 或使用 React Query 等库

## 评判标准

| 条件 | 结果 |
|------|------|
| 识别竞态 + 给出 AbortController 修复方案 | pass |
| 识别竞态但修复方案不完整 | partial pass (0.7) |
| 仅提到"建议错误处理"但未识别竞态 | fail |
| 未发现任何问题 | fail |

## 关联经验

项目 memory 中提到：`fix/modal-abort-signal` — 关闭时 AbortController 未取消的问题。
