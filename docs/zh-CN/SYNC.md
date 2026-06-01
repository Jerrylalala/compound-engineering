# 上游同步指南

本仓库是 `EveryInc/compound-engineering-plugin` 的公共 fork，保留中文化层、本地工作流增强和跨平台转换能力。

## 仓库架构

```
┌─────────────────────────────────────────────────────────────┐
│                     仓库关系图                               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  upstream (只读)                 origin (公共 fork)            │
│  ┌──────────────────┐           ┌──────────────────┐        │
│  │ EveryInc/        │  fetch    │ Jerrylalala/     │        │
│  │ compound-        │ ────────> │ compound-        │        │
│  │ engineering-     │           │ engineering-     │        │
│  │ plugin           │           │ engineering      │        │
│  └──────────────────┘           └──────────────────┘        │
│         │                              ↑                    │
│         │ merge                        │ push               │
│         └──────────────────────────────┘                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Remotes 配置

```text
upstream -> https://github.com/EveryInc/compound-engineering-plugin.git  (上游，只读)
origin   -> https://github.com/Jerrylalala/compound-engineering.git  (当前公共 fork)
```

---

## 自动化检测（推荐）

使用 `/ce:sync-upstream` 命令可自动检测上游更新：
- 自动获取 4 个上游仓库最近 30 天的变更
- 智能过滤噪音，分析相关性
- 生成结构化报告供决策

详见配置文件 `docs/sync-reports/upstream-repos.json`，支持动态添加/移除监控仓库。

手动合并步骤见下方。

---

## 同步步骤

### 第一步：检测上游更新

```bash
# 获取上游最新状态
git fetch upstream

# 查看本地与上游的差异
git log --oneline HEAD..upstream/main
```

- **有输出** → 上游有新提交，继续下一步
- **无输出** → 上游没有更新，流程结束

### 第二步：合并上游

```bash
# 确保在 main 分支
git checkout main

# 合并上游
git merge upstream/main
```

### 第三步：处理冲突（如有）

| 文件类型 | 处理方式 |
|---------|---------|
| 上游英文文件 | 接受上游版本 (`git checkout --theirs`) |
| `docs/zh-CN/*` | 保留本地版本 (`git checkout --ours`) |
| `skills-custom/*` | 保留本地版本 |
| `CLAUDE.md` | 手动合并，保留两边内容 |

```bash
# 解决冲突后
git add .
git commit -m "Merge upstream/main - 同步上游更新"
```

### 第四步：推送到公共 fork

```bash
git push origin main
```

### 第五步：更新组件统计（如有变化）

```powershell
# 统计组件数量
(Get-ChildItem -Recurse plugins/compound-engineering/agents/*.md).Count
(Get-ChildItem -Recurse plugins/compound-engineering/commands/*.md).Count
(Get-ChildItem -Directory plugins/compound-engineering/skills/).Count
```

需要同步更新的地方：
- `CLAUDE.md` → 当前组件统计表格
- `.claude-plugin/marketplace.json` → description
- `plugins/compound-engineering/.claude-plugin/plugin.json` → description

---

## 冲突处理原则

**核心策略：只新增，不修改上游文件**

| 冲突类型 | 处理方式 | 原因 |
|---------|---------|------|
| 上游英文文件 | **接受上游版本** | 保持与上游一致 |
| 中文镜像文件 | 按需重新生成 | 本地内容独立管理 |
| `skills-custom/` | 应无冲突 | 上游没有此目录 |
| `docs/zh-CN/` | 应无冲突 | 上游没有此目录 |

---

## 完整流程图

```
用户触发同步
     ↓
[检测上游] ─── 无更新 ──→ 结束
     │
   有更新
     ↓
[显示更新列表] → 用户确认
     ↓
[合并上游] ─── 有冲突 ──→ [解决冲突] → 用户确认
     │
   无冲突
     ↓
[推送到 origin]
     ↓
[更新组件统计（如需）]
     ↓
   完成
```

---

## 常见问题

### Q：如何确认当前是否已与上游对齐？

```bash
git fetch upstream
git log --oneline --decorate --graph --all -n 20
```

### Q：如何添加上游远程仓库？

```bash
git remote add upstream https://github.com/EveryInc/compound-engineering-plugin.git
git remote -v
```

### Q：skills-custom 会同步到上游吗？

不会。`skills-custom/` 是当前 fork 的本地增强目录，上游仓库没有这个目录。

---

## 同步检查清单

每次同步后确认：

- [ ] 上游英文文件未被意外修改
- [ ] 中文文档仍然完整 (`docs/zh-CN/`)
- [ ] 自定义技能仍然存在 (`skills-custom/`)
- [ ] 重新安装插件或重启 Claude Code 验证
