---
title: "SessionStart hook type:prompt 导致 startup hook error"
category: integration-issues
tags: [hooks, sessionstart, plugin, cross-platform, windows]
module: hooks
symptoms:
  - "SessionStart:startup hook error"
  - type prompt 在 SessionStart 上报错
  - type command 在 Windows 上阻塞终端
root_cause: "SessionStart 不支持 type:prompt，type:command 在 Windows 阻塞 stdin"
severity: medium
date_resolved: "2026-02-04"
---

# SessionStart Hook type:prompt 不被支持

## 问题

插件 hooks.json 使用 `type: "prompt"` 的 SessionStart hook：

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "prompt", "prompt": "..." }
        ]
      }
    ]
  }
}
```

每次打开 Claude Code 会话都报 `SessionStart:startup hook error`。

## 根因

1. **`type: "prompt"` 在 SessionStart 上不被支持** — 官方插件从未使用此组合
2. **`type: "command"` 在 Windows 上阻塞终端** — stdin 被占用，需按回车恢复

两种方式都不可用。

## 解决方案

**不使用 hooks 注入静态 prompt，改用插件 CLAUDE.md。**

插件的 CLAUDE.md 在插件启用时自动作为系统上下文加载，适合放静态内容。

```json
// hooks.json - 清空
{ "description": "...", "hooks": {} }
```

提交：`9d841bb`

## 关键排查方法

1. 清空 hooks → 确认是 hook 导致
2. 最简 prompt hook → 确认是 type:prompt 的问题
3. 换 type:command → 确认 command 可用但会卡
4. 对比官方插件 → 确认没有先例

## 关联

- 全局经验：`~/.compound/solutions/claude-code-sessionstart-hook-prompt-type-bug.md`
