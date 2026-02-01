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

**开始工作前检查历史经验**：在修复 bug 或实现功能前，先搜索 `docs/solutions/` 查找相关经验：
```bash
# 搜索相关文档
Grep pattern="关键词" path=docs/solutions/ output_mode=files_with_matches
```
如果找到相关文档，先阅读再开始工作，避免重复踩坑。

**功能完成后必须询问**：当完成用户请求的功能后，必须询问用户是否要推送到 Git：
> "功能已完成。要推送到 Git 吗？"

### 当前组件统计

| 组件        | 数量 | 位置                                     |
| ----------- | ---- | ---------------------------------------- |
| Agents      | 28   | `plugins/compound-engineering/agents/`   |
| Commands    | 26   | `plugins/compound-engineering/commands/` |
| Skills      | 17   | `plugins/compound-engineering/skills/`   |
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
│       ├── SYNC.md                   # 上游同步指南
│       ├── VERSION-STRATEGY.md       # 📌 版本管理预防策略
│       └── FORK-SETUP.md             # 📌 Fork 初始化清单
├── scripts/                          # 📌 自动化工具
│   ├── check-versions.ps1            # 版本一致性检查
│   ├── check-versions.sh             # Bash 版本
│   ├── bump-version.ps1              # 自动更新版本号
│   └── pre-commit                    # Git hook
├── plugins/
│   └── compound-engineering/
│       ├── .claude-plugin/plugin.json
│       ├── agents/                   # 28 个 agents
│       ├── commands/                 # 26 个 commands
│       ├── skills/                   # 16 个 skills
│       └── skills-custom/            # 📌 本地自定义技能
├── README.md                         # 上游英文说明（不修改）
└── CLAUDE.md                         # 本文件
```

**📌 标记** = 本地新增内容

---

## 常用操作

| 操作         | 命令                                     |
| ------------ | ---------------------------------------- |
| 同步上游     | 见 `docs/zh-CN/SYNC.md`                  |
| 添加自定义技能 | 直接在 `skills-custom/` 创建目录       |
| 统计组件数量 | 见下方                                   |

### 统计组件数量

```powershell
(Get-ChildItem -Recurse plugins/compound-engineering/agents/*.md).Count
(Get-ChildItem -Recurse plugins/compound-engineering/commands/*.md).Count
(Get-ChildItem -Directory plugins/compound-engineering/skills/).Count
```

---

## 更新插件时的检查清单

> **⚠️ 版本号必须同步！** 详见 [版本管理预防策略](docs/zh-CN/VERSION-STRATEGY.md)

### 自动化工具（推荐）

```powershell
# 自动更新版本号（推荐）
powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -BumpType patch

# 验证版本一致性
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1

# 安装 pre-commit hook（一次性）
copy scripts\pre-commit .git\hooks\pre-commit
```

### 手动检查清单

- [ ] **同步版本号** - `marketplace.json` = `plugin.json`
- [ ] **更新组件数量** - 本文件、`marketplace.json`、`plugin.json`
- [ ] **更新 CHANGELOG.md**

### 快速检查版本

```powershell
(Get-Content .claude-plugin/marketplace.json | ConvertFrom-Json).plugins[0].version
(Get-Content plugins/compound-engineering/.claude-plugin/plugin.json | ConvertFrom-Json).version
```

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

| 文档                                     | 说明               |
| ---------------------------------------- | ------------------ |
| `docs/zh-CN/INSTALL.md`                  | 安装与使用指南     |
| `docs/zh-CN/SYNC.md`                     | 上游同步指南       |
| `docs/zh-CN/VERSION-STRATEGY.md`         | 版本管理预防策略   |
| `docs/zh-CN/FORK-SETUP.md`               | Fork 仓库初始化    |
| `plugins/compound-engineering/CLAUDE.md` | 插件开发指南       |

---

## Key Learnings

### 2026-02-01：版本号同步问题

**问题**：`marketplace.json` 和 `plugin.json` 版本号不一致导致 Marketplace 无法更新。
**原因**：Marketplace 只读取 `marketplace.json` 的版本号，如果它比已安装版本旧或相同，则认为无需更新。
**解决**：每次发版必须同时更新两个文件的版本号，保持一致。

### 2026-02-01：避免特殊字符

命令描述中避免使用圆圈数字（①②③）等特殊 Unicode 字符，在某些终端显示异常。改用 `Step 1:` 等 ASCII 兼容格式。

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
