# Compound Engineering Plugin（私有镜像）

> **重要**：这是 `EveryInc/compound-engineering-plugin` 的私有镜像仓库，不是上游原始仓库。

## AI 助手快速入门

**读完这一节，你就能立即开始工作。**

### 仓库定位

```
本仓库 = 上游镜像 + 中文化层 + 本地扩展
```

| 角色 | 仓库 | 说明 |
|-----|------|------|
| **upstream** | EveryInc/compound-engineering-plugin | 上游原始仓库（只读） |
| **origin** | Jerrylalala/compound-engineering-plugin-private | 用户的私有仓库 |

### 核心原则

1. **不修改上游英文文件** - 中文内容放在独立目录
2. **只新增，不修改** - 减少同步冲突
3. **本地扩展隔离** - `skills-custom/` 不影响上游

### 当前组件统计

| 组件 | 数量 | 位置 |
|-----|------|------|
| Agents | 28 | `plugins/compound-engineering/agents/` |
| Commands | 28 | `plugins/compound-engineering/commands/` |
| Skills | 15 | `plugins/compound-engineering/skills/` |
| MCP Servers | 1 | Context7（HTTP 服务） |

### 常用操作

| 操作 | 命令 |
|------|------|
| 同步上游 | `pwsh scripts/sync-upstream.ps1` |
| 导入本地技能 | `pwsh scripts/import-skills.ps1` |
| 安装到 Codex | `bun run src/index.ts install ./plugins/compound-engineering --to codex` |

---

## 目录结构

```
compound-engineering-plugin-private/
├── .claude-plugin/
│   └── marketplace.json              # 市场配置
├── docs/
│   ├── index.html                    # 文档首页
│   ├── pages/                        # 参考页面
│   └── zh-CN/                        # 📌 中文文档（本地新增）
│       ├── README.md                 # 中文镜像策略说明
│       └── REPO-SYNC.md              # 同步指南
├── plugins/
│   └── compound-engineering/
│       ├── .claude-plugin/plugin.json
│       ├── agents/                   # 28 个 agents
│       │   ├── review/               # 代码审查 (14)
│       │   ├── research/             # 研究分析 (5)
│       │   ├── design/               # 设计 (3)
│       │   ├── workflow/             # 工作流 (5)
│       │   └── docs/                 # 文档 (1)
│       ├── commands/
│       │   ├── workflows/            # 英文工作流命令 (5)
│       │   ├── workflows-zh/         # 📌 中文工作流命令 (4)
│       │   └── *.md                  # 工具命令 (19)
│       ├── skills/                   # 上游技能 (15)
│       ├── skills-custom/            # 📌 本地自定义技能
│       ├── skills-inbox/             # 📌 技能投递箱
│       ├── README.md
│       └── CHANGELOG.md
├── scripts/
│   ├── sync-upstream.ps1             # 一键同步上游
│   └── import-skills.ps1             # 导入本地技能
├── README.md                         # 上游英文说明（不修改）
├── README.zh-CN.md                   # 📌 中文说明（本地新增）
└── CLAUDE.md                         # 本文件
```

**📌 标记** = 本地新增内容，不在上游仓库中

---

## 中文化层策略

### 文件分布

| 内容类型 | 存放位置 | 说明 |
|---------|---------|------|
| 项目中文说明 | `README.zh-CN.md` | 独立于上游 README.md |
| 中文文档 | `docs/zh-CN/` | 所有中文文档输出位置 |
| 中文命令 | `commands/workflows-zh/` | 中文版工作流命令 |
| 本地技能 | `skills-custom/` | 不影响上游 |

### 为什么这样设计？

- **减少冲突**：上游更新时，中文内容不会被覆盖
- **易于维护**：中文内容集中管理
- **可追溯**：清晰区分上游和本地内容

---

## 上游同步流程

### 一键同步

```powershell
pwsh scripts/sync-upstream.ps1
```

### 脚本执行流程

```
1. git fetch upstream          # 获取上游最新
2. git checkout main           # 切换到主分支
3. git merge upstream/main     # 合并上游
4. [检测冲突]                   # 如有冲突，停止并显示
5. git push origin main        # 推送到私有仓库
6. bun install                 # 安装依赖
7. 重新生成 Codex 输出
```

### 冲突处理原则

| 冲突类型 | 处理方式 |
|---------|---------|
| 上游英文文件 | **接受上游版本** |
| 中文镜像文件 | 按需重新生成或手动合并 |
| skills-custom/ | 应无冲突（上游没有） |
| docs/zh-CN/ | 应无冲突（上游没有） |

详见 `docs/zh-CN/REPO-SYNC.md`

---

## 添加本地技能

### 方式一：直接添加

```bash
# 在 skills-custom 中创建技能目录
mkdir plugins/compound-engineering/skills-custom/my-skill

# 创建 SKILL.md
```

### 方式二：通过投递箱

1. 把技能放入 `skills-inbox/<skill-name>/`
2. 运行：`pwsh scripts/import-skills.ps1`

---

## 更新插件时的检查清单

当添加或修改 agents、commands、skills 时：

### 1. 统计组件数量

```bash
# Windows PowerShell
(Get-ChildItem -Recurse plugins/compound-engineering/agents/*.md).Count
(Get-ChildItem -Recurse plugins/compound-engineering/commands/*.md).Count
(Get-ChildItem -Directory plugins/compound-engineering/skills/).Count
```

### 2. 更新配置文件中的数量

需要同步更新的地方：

- [ ] `.claude-plugin/marketplace.json` → description
- [ ] `plugins/compound-engineering/.claude-plugin/plugin.json` → description
- [ ] `plugins/compound-engineering/README.md` → Components 表格

### 3. 更新版本号

- [ ] `.claude-plugin/marketplace.json` → version
- [ ] `plugins/compound-engineering/.claude-plugin/plugin.json` → version

### 4. 更新文档

- [ ] `plugins/compound-engineering/CHANGELOG.md`
- [ ] 如有必要，运行 `claude /release-docs`

---

## 提交规范

```
Add [agent/command name] - 添加新功能
Remove [agent/command name] - 移除功能
Update [file] to [what changed] - 更新文件
Fix [issue] - Bug 修复

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## 相关文档

| 文档 | 说明 |
|-----|------|
| `docs/zh-CN/README.md` | 中文文档首页和镜像策略 |
| `docs/zh-CN/REPO-SYNC.md` | 详细的同步指南 |
| `plugins/compound-engineering/CLAUDE.md` | 插件开发指南 |
| `plugins/compound-engineering/README.md` | 插件使用说明 |

---

## Key Learnings

### 2026-01-30：建立中文镜像策略

建立了完整的中文化层策略，包括：
- 中文文档集中在 `docs/zh-CN/`
- 中文命令在 `commands/workflows-zh/`
- 本地技能在 `skills-custom/`
- 详细的同步指南在 `REPO-SYNC.md`

**学习**：通过"只新增，不修改"的策略，可以最大限度减少与上游的冲突。

### 2024-11-22：组件数量不一致问题

发现配置文件中的组件数量与实际文件数量不符。

**学习**：每次更新前必须先统计实际文件数量，然后同步更新所有配置文件。

### 2024-10-09：marketplace.json 结构简化

去除了不在官方规范中的自定义字段。

**学习**：只使用官方规范中定义的字段，避免兼容性问题。
