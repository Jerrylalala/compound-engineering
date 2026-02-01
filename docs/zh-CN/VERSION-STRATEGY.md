# 版本管理预防策略

> 本文档定义版本号不一致和身份信息冲突的预防措施。

---

## 问题 1: 版本号不一致

### 问题描述

需要同步 **4 个位置** 的版本信息：

| 文件 | 字段 | 说明 |
|------|------|------|
| `.claude-plugin/marketplace.json` | `plugins[0].version` | Marketplace 读取的版本 |
| `plugins/.../plugin.json` | `version` | 插件本身版本 |
| `CHANGELOG.md` | 标题 | 变更记录 |
| `README.md` / `plugin.json` description | 组件数量 | agents/commands/skills 数量 |

### 风险

- Marketplace 无法检测到更新（版本号相同或更低）
- 用户看到不一致的版本信息，产生困惑
- 组件数量过时，误导用户

### 预防措施

#### 措施 1: 使用自动化脚本（推荐）

```powershell
# 自动递增 patch 版本并同步
powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -BumpType patch

# 或直接指定版本
powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -Version "2.30.0"
```

脚本会自动：
1. 更新 `marketplace.json` 中的版本
2. 更新 `plugin.json` 中的版本
3. 验证同步成功
4. 提示下一步操作

#### 措施 2: 安装 pre-commit hook

```bash
# 安装 hook
cp scripts/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit  # macOS/Linux

# Windows 下需要确保 Git Bash 可执行
```

hook 会在提交时检查版本一致性，不一致则阻止提交。

#### 措施 3: 手动检查（备选）

提交前运行验证脚本：

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1

# macOS/Linux
bash scripts/check-versions.sh
```

### 发版检查清单

每次发版必须完成：

- [ ] **版本号同步** - 运行 `bump-version.ps1` 或手动同步
- [ ] **CHANGELOG 更新** - 记录本次变更内容
- [ ] **组件数量核对** - 如有新增/删除，更新以下位置：
  - `CLAUDE.md` 当前组件统计表
  - `marketplace.json` 插件描述
  - `plugin.json` 描述字段
- [ ] **运行验证脚本** - 确认所有检查通过
- [ ] **测试安装** - 在新环境测试 Marketplace 安装

---

## 问题 2: Fork 仓库身份信息冲突

### 问题描述

从上游 fork 后，以下信息仍指向原仓库：

- `marketplace.json` 的 owner 信息
- `plugin.json` 的 author/homepage/repository
- `CLAUDE.md` 中的安装命令

### 风险

- Claude Code 无法正确识别私有仓库
- 安装指向错误的仓库
- 上游同步时产生合并冲突

### 预防措施

#### 措施 1: Fork 后立即初始化

参考 [Fork 仓库初始化清单](./FORK-SETUP.md)，在 fork 后第一时间完成身份信息修改。

#### 措施 2: 上游同步时保护身份信息

同步上游更新时，使用以下策略：

```bash
# 1. 获取上游更新
git fetch upstream

# 2. 查看冲突文件
git diff upstream/main -- .claude-plugin/marketplace.json
git diff upstream/main -- plugins/compound-engineering/.claude-plugin/plugin.json

# 3. 合并时保留本地身份信息
git merge upstream/main --no-commit

# 4. 如果身份信息被覆盖，恢复本地版本
git checkout --ours .claude-plugin/marketplace.json
git checkout --ours plugins/compound-engineering/.claude-plugin/plugin.json

# 5. 手动合并其他内容（如版本号需要更新）
# 编辑文件，保留你的身份信息，使用上游的新功能

# 6. 完成合并
git add .
git commit -m "Sync upstream changes, preserve local identity"
```

#### 措施 3: 使用 .gitattributes 保护文件（高级）

在仓库根目录创建 `.gitattributes`：

```gitattributes
# 合并时优先使用本地版本（谨慎使用）
# .claude-plugin/marketplace.json merge=ours
# plugins/compound-engineering/.claude-plugin/plugin.json merge=ours
```

> 注意：此方法会完全忽略上游对这些文件的更改，可能错过重要更新。

---

## 自动化工具清单

| 脚本 | 用途 | 使用方式 |
|------|------|----------|
| `scripts/check-versions.ps1` | 验证版本一致性 | 提交前运行 |
| `scripts/check-versions.sh` | 验证版本一致性 (Bash) | 提交前运行 |
| `scripts/bump-version.ps1` | 自动更新版本号 | 发版时运行 |
| `scripts/pre-commit` | Git hook | 安装到 `.git/hooks/` |

---

## 最佳实践总结

### 日常开发

1. 修改功能后，使用 `bump-version.ps1 -BumpType patch` 更新版本
2. 提交前运行 `check-versions.ps1` 验证
3. 确保 CHANGELOG 记录了变更

### 上游同步

1. 同步前备份身份信息相关文件
2. 合并后检查身份信息是否被覆盖
3. 运行 `check-versions.ps1` 确认一致性

### 新人入职/Fork 初始化

1. Fork 后第一时间按 [FORK-SETUP.md](./FORK-SETUP.md) 初始化
2. 安装 pre-commit hook
3. 测试一次完整的版本更新流程

---

## 相关文档

- [Fork 仓库初始化清单](./FORK-SETUP.md)
- [上游同步指南](./SYNC.md)
- [安装与使用](./INSTALL.md)
