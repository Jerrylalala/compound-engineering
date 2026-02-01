# Compound Engineering Plugin（私有镜像）

> **重要**：这是 `EveryInc/compound-engineering-plugin` 的私有镜像仓库。

## AI 助手快速入门

### 仓库定位

```
本仓库 = 上游镜像 + 中文化层 + 本地扩展
```

| 角色         | 仓库                                            | 说明                 |
| ------------ | ----------------------------------------------- | -------------------- |
| **upstream** | EveryInc/compound-engineering-plugin            | 上游原始仓库（只读） |
| **origin**   | Jerrylalala/compound-engineering-plugin-private | 用户的私有仓库       |

### 核心原则

1. **不修改上游英文文件** - 中文内容放在独立目录
2. **只新增，不修改** - 减少同步冲突
3. **本地扩展隔离** - `skills-custom/` 不影响上游

### AI 助手行为规范

**功能完成后必须询问**：当完成用户请求的功能后，必须询问用户是否要推送到 Git：
> "功能已完成。要推送到 Git 吗？"

### 当前组件统计

| 组件        | 数量 | 位置                                     |
| ----------- | ---- | ---------------------------------------- |
| Agents      | 28   | `plugins/compound-engineering/agents/`   |
| Commands    | 24   | `plugins/compound-engineering/commands/` |
| Skills      | 16   | `plugins/compound-engineering/skills/`   |
| MCP Servers | 1    | Context7（HTTP 服务）                    |

### 安装方式

**推荐：通过 Marketplace 从 GitHub 安装**

```
/plugins → Add marketplace → Jerrylalala/compound-engineering-plugin-private
```

**本地开发：**

```bash
claude --plugin-dir "完整路径\plugins\compound-engineering"
```

---

## 目录结构

```
compound-engineering-plugin-private/
├── .claude-plugin/
│   └── marketplace.json
├── docs/
│   └── zh-CN/                        # 📌 中文文档
│       ├── INSTALL.md                # 安装与使用指南
│       └── SYNC.md                   # 上游同步指南
├── plugins/
│   └── compound-engineering/
│       ├── .claude-plugin/plugin.json
│       ├── agents/                   # 28 个 agents
│       ├── commands/                 # 24 个 commands
│       ├── skills/                   # 16 个 skills
│       ├── skills-custom/            # 📌 本地自定义技能
│       └── skills-inbox/             # 📌 技能投递箱
├── scripts/
│   ├── sync-upstream.ps1
│   └── import-skills.ps1
├── README.md                         # 上游英文说明（不修改）
└── CLAUDE.md                         # 本文件
```

**📌 标记** = 本地新增内容

---

## 常用操作

| 操作         | 命令                             |
| ------------ | -------------------------------- |
| 同步上游     | `pwsh scripts/sync-upstream.ps1` |
| 导入本地技能 | `pwsh scripts/import-skills.ps1` |
| 统计组件数量 | 见下方                           |

### 统计组件数量

```powershell
(Get-ChildItem -Recurse plugins/compound-engineering/agents/*.md).Count
(Get-ChildItem -Recurse plugins/compound-engineering/commands/*.md).Count
(Get-ChildItem -Directory plugins/compound-engineering/skills/).Count
```

---

## 更新插件时的检查清单

- [ ] 更新版本号：`.claude-plugin/marketplace.json` 和 `plugin.json`
- [ ] 更新组件数量：本文件、`marketplace.json`、`plugin.json`
- [ ] 更新 `CHANGELOG.md`

---

## 提交规范

```
Add [agent/command name] - 添加新功能
Update [file] to [what changed] - 更新文件
Fix [issue] - Bug 修复

Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## 相关文档

| 文档                                     | 说明           |
| ---------------------------------------- | -------------- |
| `docs/zh-CN/INSTALL.md`                  | 安装与使用指南 |
| `docs/zh-CN/SYNC.md`                     | 上游同步指南   |
| `plugins/compound-engineering/CLAUDE.md` | 插件开发指南   |

---

## Key Learnings

### 2026-01-31：安装方式更新

**推荐方式**：通过 Marketplace 从 GitHub 安装
```
/plugins → Add marketplace → Jerrylalala/compound-engineering-plugin-private
```

**备选方式**：本地开发用 `--plugin-dir`

### 2026-01-31：MCP 服务器限制

插件只能配置**无需认证的 HTTP 类型** MCP 服务器：
- ✅ Context7（已配置）
- ⚠️ GitHub MCP 需要用户自行认证，建议全局安装

### 2026-01-31：文档整合

将 6 个文档整合为 3 个：
- `CLAUDE.md` - 项目指令
- `docs/zh-CN/INSTALL.md` - 安装与使用
- `docs/zh-CN/SYNC.md` - 上游同步

### 2026-01-30：中文镜像策略

- 中文文档集中在 `docs/zh-CN/`
- 本地技能在 `skills-custom/`
- "只新增，不修改"减少冲突
