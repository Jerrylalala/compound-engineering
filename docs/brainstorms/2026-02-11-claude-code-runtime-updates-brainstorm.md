---
type: brainstorm
date: 2026-02-11
topic: Claude Code 2.1.27-2.1.38 Runtime Updates Integration
participants:
  - Pragmatic Engineer (Claude)
  - Plugin Architect (Claude)
  - Power User (Claude)
  - Codex (GPT-5.2)
  - Gemini (2.5-Pro)
status: decided
---

# Claude Code 运行时更新对插件的影响分析

**日期**: 2026-02-11
**分析范围**: Claude Code v2.1.27 (Jan 31) → v2.1.38 (Feb 10)
**插件版本**: compound-engineering-plugin-private v2.41.0

## What We're Building

评估 Claude Code 10 项运行时更新对插件的影响，决定哪些需要整合、哪些自动受益、哪些无关。

## Why This Approach

采用五方协作评估（3 Claude 专家 + Codex + Gemini），确保评估全面且交叉验证。

---

## 更新分类

### A. 插件应主动整合（3 项）

#### 1. Memory Frontmatter（2.1.33）

**官方语法**: `memory: user | project | local`
- 不写 memory 字段 = 无持久记忆（默认）
- `project` = 项目级别记忆，适合研究型 agents
- `user` = 用户级别记忆，适合跨项目偏好
- `local` = 机器级别，适合环境配置

**推荐启用的 Agents**（4-6 个）:

| Agent | 推荐值 | 理由 |
|-------|--------|------|
| learnings-researcher | `project` | 跨会话积累项目经验 |
| best-practices-researcher | `project` | 缓存常用最佳实践 |
| git-history-analyzer | `project` | 记住仓库演进模式 |
| architecture-strategist | `project` | 记住架构决策历史 |
| repo-research-analyst | `project` | 缓存仓库结构认知 |
| framework-docs-researcher | `user` | 跨项目共享框架知识 |

**投入**: 1-2 小时
**收益**: 减少重复搜索，跨会话知识积累
**风险**: 低（只添加一行 frontmatter）

来源: [code.claude.com/docs/en/sub-agents](https://code.claude.com/docs/en/sub-agents)

---

#### 2. PDF Pages 支持（2.1.30）

**更新内容**: Read 工具支持 `pages: "1-5"` 参数，每次最多 20 页。

**插件整合方式**: 更新 `document-review` skill，添加 PDF 处理指引。

**投入**: 30 分钟
**收益**: 支持大型 PDF 设计稿/规范文档审查
**风险**: 极低（只是文档更新）

---

#### 3. Fast Mode 引导（2.1.36）

**更新内容**: `/fast` 切换 Opus 4.6 快速模式（相同模型，更快输出）。

**插件整合方式**: 在 workflows 命令中添加性能提示。

**投入**: 30 分钟
**收益**: 用户体验提升，长任务加速
**风险**: 极低

---

### B. 自动受益，无需插件行动（5 项）

| 更新 | 版本 | 说明 |
|------|------|------|
| 68% resume 内存优化 | 2.1.30 | 会话恢复更快更省内存 |
| Sandbox 安全修复 | 2.1.34 | 修复沙箱绕过漏洞 |
| VS Code 远程会话 | 2.1.32 | IDE 用户自动受益 |
| `/debug` 端点 | 2.1.30 | 自助故障排除 |
| `--from-pr` 标志 | 2.1.27 | PR 关联会话恢复 |

---

### C. 观望/暂缓（2 项）

#### Agent Teams 试点

- **现状**: 已有 `orchestrating-swarms` skill（1718 行）
- **建议**: 仅创建 1 个试点场景（如 review-debate），标注实验性
- **原因**: Agent Teams 仍为实验功能，成本高
- 来源: [code.claude.com/docs/en/agent-teams](https://code.claude.com/docs/en/agent-teams)

#### TeammateIdle/TaskCompleted Hooks

- **现状**: hooks.json 已清空（之前实验失败）
- **建议**: 暂缓，等运行时 bug 修复后重新评估
- **位置**: 只能在 `hooks.json` 或 `plugin.json` 中配置，不能在 .md 中声明
- 来源: [docs.claude.com](https://docs.claude.com/en/docs/claude-code/plugins-reference)

---

## Key Decisions

1. **Memory 策略**: 选择性启用 4-6 个研究型 agents（`memory: project`），其余不写（无记忆）
2. **不存在 `memory: false` 或 `memory: long-term`**: Codex 纠正了初始假设
3. **Agent Teams**: 不全面铺开，已有 orchestrating-swarms 足够
4. **Hooks**: 暂不使用 TeammateIdle/TaskCompleted，历史经验证明风险高
5. **投入预算**: 约 2-3 小时完成全部 3 项整合

## Open Questions

1. `memory: project` 的实际 token 节省量需要测试验证
2. Agent Teams 未来是否会从"实验性"升级为"稳定"
3. hooks 系统的 Windows 兼容性是否已改善

## 五方共识度

| 建议 | 务实 | 架构 | 用户 | Codex | Gemini | 共识 |
|------|:----:|:----:|:----:|:-----:|:------:|:----:|
| Memory 选择性启用 | 5 | 5 | 5 | 5 | 5 | **5/5** |
| PDF pages 支持 | 5 | 3 | 4 | 4 | 3 | **4/5** |
| Fast mode 引导 | 4 | 2 | 4 | 3 | 2 | **3/5** |
| Agent Teams 试点 | 1 | 3 | 5 | 2 | 2 | **2/5** |
| Hooks 自动化 | 1 | 1 | 5 | 1 | 1 | **1/5** |

## Next Steps

当用户准备实施时，运行 `/workflows:plan` 自动检测此 brainstorm 文档。

**预计版本**: v2.42.0
**预计投入**: 2-3 小时
**预计变更**: 6 个 agent .md + 1 个 skill .md + 2 个 command .md
