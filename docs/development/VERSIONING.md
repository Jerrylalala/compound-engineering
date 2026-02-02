# 版本管理规范

> **单一信息源**：本文件是版本管理规则的权威来源。

## 必须同步的文件

每次发版必须更新以下文件：

| 文件 | 更新内容 |
|------|---------|
| `.claude-plugin/marketplace.json` | version 字段 |
| `plugins/compound-engineering/.claude-plugin/plugin.json` | version 字段 |
| `plugins/compound-engineering/CHANGELOG.md` | 版本记录 |
| `plugins/compound-engineering/README.md` | 组件数量（如有变化） |

## 版本号规则（Semver）

| 类型 | 格式 | 何时使用 |
|------|------|---------|
| **MAJOR** | X.0.0 | 破坏性变更、大重构 |
| **MINOR** | x.Y.0 | 新增 agents/commands/skills |
| **PATCH** | x.y.Z | Bug 修复、文档更新、小改进 |

## 发版检查清单

```markdown
### 版本文件
- [ ] marketplace.json 版本号已更新
- [ ] plugin.json 版本号已更新（必须与上面一致）
- [ ] CHANGELOG.md 添加了版本记录

### 组件数量（如有变化）
- [ ] README.md 组件表格已更新
- [ ] marketplace.json description 数量已更新
- [ ] plugin.json description 数量已更新
- [ ] 根目录 CLAUDE.md 数量已更新

### 文档更新（如有新功能）
- [ ] docs/zh-CN/INSTALL.md 使用说明已更新
- [ ] CHANGELOG.md 包含新功能描述
```

## 自动化工具

```powershell
# 1. 自动更新版本号
powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -BumpType patch

# 2. 检查版本一致性
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1

# 3. 安装 pre-commit hook（一次性）
Copy-Item scripts/pre-commit .git/hooks/pre-commit -Force
```

## 常见问题

### Marketplace 不更新

**症状**：推送后 Marketplace 显示旧版本。

**原因**：`marketplace.json` 版本号未更新或比已安装版本低。

**解决**：
1. 确认 `marketplace.json` 版本号 > 已安装版本
2. 确认 `marketplace.json` = `plugin.json`

### 组件数量不匹配

**检查命令**：
```powershell
# 统计实际数量
(Get-ChildItem -Recurse plugins/compound-engineering/agents/*.md).Count
(Get-ChildItem -Recurse plugins/compound-engineering/commands/*.md).Count
(Get-ChildItem -Directory plugins/compound-engineering/skills/).Count
```

---

## 相关文档

- [脚本使用说明](../zh-CN/SCRIPTS.md)
- [Fork 初始化清单](../zh-CN/FORK-SETUP.md)
