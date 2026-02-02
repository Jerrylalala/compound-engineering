---
title: "Claude Code 插件 Marketplace 更新失败与终端序号显示异常"
category: integration-issues
tags:
  - claude-code
  - plugin
  - marketplace
  - version-sync
  - fork
  - terminal-compatibility
  - unicode
symptoms:
  - "Marketplace 点击 'Update now' 时报错 'Local plugins cannot be updated remotely'"
  - "Workflow 命令中的圆圈数字序号（①②③④⑤⑥⓪）在部分终端显示为乱码或方框"
  - "插件版本号不一致（marketplace.json vs plugin.json）"
  - "修改 GitHub 上的 marketplace.json 后，Claude Code 中的 marketplace 名称不更新"
  - "插件加载失败，显示 'failed to load · 1 error'"
module: compound-engineering-plugin
date_resolved: "2026-02-01"
version_fixed: "2.29.0"
---

# Claude Code 插件 Marketplace 更新失败与终端序号显示异常

## 问题症状

1. **Marketplace 更新失败**：点击 "Update now" 时报错 `Local plugins cannot be updated remotely`
2. **序号显示异常**：`①②③④⑤⑥⓪` 在某些终端显示为方框或乱码
3. **版本号不一致**：marketplace.json 显示 2.28.0，plugin.json 显示 2.29.0
4. **Marketplace 名称不更新**：修改 GitHub 上的 `marketplace.json` 后，Claude Code 中仍显示旧名称
5. **插件加载失败**：显示 "failed to load · 1 error"

## 根本原因

### 问题1：Marketplace 更新失败

私有 fork 仓库沿用了上游的身份信息，导致 Claude Code 识别冲突：

| 配置项 | 问题 |
|--------|------|
| marketplace 名称 | `every-marketplace` 和上游同名 |
| owner | 指向上游作者 Kieran Klaassen |
| repository | 指向上游仓库 `EveryInc/...` |
| homepage | 指向上游网站 |

Claude Code 检测到：
1. marketplace 名称是 `every-marketplace`
2. 但 repository 指向 `EveryInc/...`（上游）
3. 而实际仓库是 `Jerrylalala/...`（私有 fork）
4. **身份信息冲突** → 被识别为"本地修改的插件" → 无法远程更新

### 问题2：Marketplace 名称缓存不更新

Claude Code 首次添加 marketplace 时会读取 `marketplace.json` 并**缓存**以下元数据：
- `name` - marketplace 名称
- `owner` - 所有者信息
- `metadata` - 其他元数据

**缓存行为**：
1. 之后即使 GitHub 上修改了 `marketplace.json`，Claude Code **不会自动更新**这些元数据
2. 只有**移除并重新添加** marketplace 才会重新读取
3. 缓存位置：`~/.claude/plugins/marketplaces/[marketplace-name]/`

**影响**：
- 用户修改 `name: "every-marketplace"` → `name: "jerry-marketplace"` 后
- Claude Code 仍显示 `every-marketplace`
- 导致用户误以为修改没有生效

### 问题3：序号显示异常

Unicode 圆圈数字（U+2460-U+2464 等）依赖终端字体支持：
- Windows CMD：可能显示为方框
- 非 UTF-8 终端：显示为乱码
- SSH 会话：取决于终端配置

### 问题4：版本号不一致

需要同步的 4 个位置未全部更新：
1. `.claude-plugin/marketplace.json`
2. `plugins/compound-engineering/.claude-plugin/plugin.json`
3. `plugins/compound-engineering/CHANGELOG.md`
4. `plugins/compound-engineering/README.md`

## 解决方案

### 1. 修复序号显示

将所有圆圈数字替换为 ASCII 兼容格式：

```diff
- description: ① 探索需求和方案
+ description: "Step 1: 探索需求和方案"
```

涉及文件：
- `commands/workflows/brainstorm.md` → Step 1:
- `commands/workflows/plan.md` → Step 2:
- `commands/workflows/work.md` → Step 3:
- `commands/workflows/review.md` → Step 4:
- `commands/workflows/compound.md` → Step 5:
- `commands/workflows/save.md` → Step 6:
- `commands/workflows/load.md` → Step 0:

### 2. 修复身份信息冲突

修改 marketplace 名称和身份信息为独特值：

**`.claude-plugin/marketplace.json`:**
```json
{
  "name": "jerry-marketplace",
  "owner": {
    "name": "Jerry Jian",
    "url": "https://github.com/Jerrylalala"
  },
  "plugins": [{
    "author": {
      "name": "Jerry Jian (fork of Kieran Klaassen)",
      "url": "https://github.com/Jerrylalala"
    },
    "homepage": "https://github.com/Jerrylalala/compound-engineering-plugin-private"
  }]
}
```

**`plugins/.../plugin.json`:**
```json
{
  "author": {
    "name": "Jerry Jian (fork of Kieran Klaassen)",
    "url": "https://github.com/Jerrylalala"
  },
  "homepage": "https://github.com/Jerrylalala/compound-engineering-plugin-private",
  "repository": "https://github.com/Jerrylalala/compound-engineering-plugin-private"
}
```

### 3. 同步版本号

使用自动化工具：

```powershell
# 自动更新版本号
powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -BumpType patch

# 验证版本一致性
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1
```

### 4. 重新安装插件（重要）

> ⚠️ **关键发现**：Claude Code 首次添加 marketplace 时会**缓存** `name` 字段，之后即使 GitHub 上修改了 `marketplace.json`，也**不会自动更新名称**。必须先移除再重新添加。

**方法 A：通过 UI 操作（推荐）**

1. 打开 `/plugin` 界面
2. 切换到 **Marketplaces** 标签
3. 选中旧的 marketplace（如 `every-marketplace`）
4. 按 **`r`** 移除
5. 选择 **`+ Add Marketplace`**
6. 输入：`Jerrylalala/compound-engineering-plugin-private`
7. 新名称 `jerry-marketplace` 会正确显示

**方法 B：手动删除缓存**

```powershell
# 删除旧缓存
Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\plugins\marketplaces\every-marketplace"

# 重启 Claude Code 后重新添加
# /plugins → Add marketplace → Jerrylalala/compound-engineering-plugin-private
```

### 5. 验证修复

修复后检查：
1. `/plugin` → Marketplaces：名称显示为 `jerry-marketplace`
2. `/plugin` → Installed：插件状态为正常加载（无 "failed to load" 错误）

## 预防策略

### 版本号同步

1. **安装 pre-commit hook**：`copy scripts\pre-commit .git\hooks\pre-commit`
2. **使用自动化工具**：`scripts/bump-version.ps1`
3. **每次提交前检查**：`scripts/check-versions.ps1`

### Fork 仓库初始化

Fork 后立即执行：
1. 修改 marketplace 名称为独特名称
2. 更新所有 owner/author 信息
3. 更新 repository/homepage 指向私有仓库

详见：[Fork 仓库初始化清单](../../zh-CN/FORK-SETUP.md)

### 避免特殊字符

CLI 输出中避免使用 Unicode 特殊字符（如 ①②③），优先使用 ASCII 兼容格式（如 `Step 1:`）。

> **详细规范**：参见 `plugins/compound-engineering/CLAUDE.md` 的「序号格式规范」

> **经验分类规则**：参见 `~/.claude/CLAUDE.md` 的「经验分类规则（SSOT）」

## 相关文档

- [版本管理预防策略](../../zh-CN/VERSION-STRATEGY.md)
- [Fork 仓库初始化清单](../../zh-CN/FORK-SETUP.md)
- [插件版本管理规范](../../development/VERSIONING.md)

