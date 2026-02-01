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
module: compound-engineering-plugin
date_resolved: "2026-02-01"
version_fixed: "2.29.0"
---

# Claude Code 插件 Marketplace 更新失败与终端序号显示异常

## 问题症状

1. **Marketplace 更新失败**：点击 "Update now" 时报错 `Local plugins cannot be updated remotely`
2. **序号显示异常**：`①②③④⑤⑥⓪` 在某些终端显示为方框或乱码
3. **版本号不一致**：marketplace.json 显示 2.28.0，plugin.json 显示 2.29.0

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

### 问题2：序号显示异常

Unicode 圆圈数字（U+2460-U+2464 等）依赖终端字体支持：
- Windows CMD：可能显示为方框
- 非 UTF-8 终端：显示为乱码
- SSH 会话：取决于终端配置

### 问题3：版本号不一致

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

### 4. 重新安装插件

```powershell
# 删除旧缓存
Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\plugins\marketplaces\every-marketplace"

# 重启 Claude Code 后重新添加
# /plugins → Add marketplace → Jerrylalala/compound-engineering-plugin-private
```

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

CLI 输出中避免使用 Unicode 特殊字符，优先使用 ASCII 兼容格式。

### Workflow 命令序号规范

已在 `plugins/compound-engineering/CLAUDE.md` 中添加明确规范：

**完整命令列表：**

| 序号 | 命令 | 说明 |
|------|------|------|
| Step 0: | `/workflows:load` | 加载项目上下文 |
| Step 1: | `/workflows:brainstorm` | 探索需求和方案 |
| Step 2: | `/workflows:plan` | 创建实施计划 |
| Step 3: | `/workflows:work` | 执行工作计划 |
| Step 4: | `/workflows:review` | 代码审查 |
| Step 5: | `/workflows:compound` | 记录解决方案 |
| Step 6: | `/workflows:save` | 保存项目上下文 |

**格式规范：**
```yaml
# ✅ 正确
description: "Step X: 描述内容"

# ❌ 错误
description: ① 描述内容
```

新增 workflow 命令时，按顺序分配 Step 编号，确保使用 ASCII 格式。

## 全局经验库架构

为了让经验跨项目生效，建立了双层经验库：

### 架构

```
~/.claude/
├── CLAUDE.md              ← 全局规则（所有项目生效）
└── solutions/             ← 全局经验库（通用经验）
    └── *.md

任何项目/
├── CLAUDE.md              ← 项目规则
└── docs/solutions/        ← 项目经验库（项目特定经验）
    └── *.md
```

### 搜索规则（已添加到全局 CLAUDE.md）

```bash
# 1. 搜索全局经验库（通用经验）
Grep pattern="关键词" path=~/.claude/solutions/ output_mode=files_with_matches

# 2. 搜索项目经验库（项目特定经验）
Grep pattern="关键词" path=docs/solutions/ output_mode=files_with_matches
```

### 经验分类

| 经验类型 | 放入位置 |
|----------|----------|
| Claude Code 使用问题 | `~/.claude/solutions/` |
| 开发工具/IDE 问题 | `~/.claude/solutions/` |
| Git/GitHub 通用问题 | `~/.claude/solutions/` |
| 项目业务逻辑 bug | `项目/docs/solutions/` |
| 项目特定架构问题 | `项目/docs/solutions/` |

### 生效范围

- **全局规则**：在任何项目中，AI 都会先搜索 `~/.claude/solutions/`
- **项目规则**：如果项目有 `docs/solutions/`，也会搜索

## 相关文档

- [版本管理预防策略](../../zh-CN/VERSION-STRATEGY.md)
- [Fork 仓库初始化清单](../../zh-CN/FORK-SETUP.md)
- [插件版本管理规范](../plugin-versioning-requirements.md)
