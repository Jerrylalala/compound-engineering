# 脚本使用说明

本项目提供自动化脚本来简化版本管理和发布流程。

## 脚本列表

| 脚本 | 用途 | 平台 |
|------|------|------|
| `check-versions.ps1` | 检查版本一致性 | Windows |
| `check-versions.sh` | 检查版本一致性 | Linux/macOS |
| `bump-version.ps1` | 自动更新版本号 | Windows |
| `pre-commit` | Git 提交前检查 | 通用 |

---

## check-versions（版本检查）

检查 `marketplace.json` 和 `plugin.json` 的版本号是否一致。

### Windows

```powershell
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1
```

### Linux/macOS

```bash
bash scripts/check-versions.sh
```

### 输出示例

```
========================================
  Version Consistency Check
========================================

[INFO] Checking file existence...
[INFO] Reading version numbers...
  marketplace.json: 2.32.0
  plugin.json:      2.32.0
[INFO] Comparing versions...
[OK] Versions match: 2.32.0

[INFO] Checking component counts...
  Actual: Agents=28, Commands=26, Skills=20
  Declared: Agents=28, Commands=26, Skills=20
[OK] Component counts match

========================================
  ALL CHECKS PASSED
========================================
```

---

## bump-version（版本更新）

自动更新所有版本号文件。

### 用法

```powershell
# Patch 版本 (2.32.0 → 2.32.1)
powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -BumpType patch

# Minor 版本 (2.32.0 → 2.33.0)
powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -BumpType minor

# Major 版本 (2.32.0 → 3.0.0)
powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -BumpType major
```

### 更新的文件

1. `.claude-plugin/marketplace.json`
2. `plugins/compound-engineering/.claude-plugin/plugin.json`

---

## pre-commit（提交前检查）

Git pre-commit hook，在提交前自动运行版本检查。

### 安装

```powershell
# Windows
Copy-Item scripts/pre-commit .git/hooks/pre-commit -Force

# Linux/macOS
cp scripts/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### 工作原理

1. 检测是否有版本相关文件被修改
2. 如果有，自动运行 `check-versions` 脚本
3. 检查失败则阻止提交

---

## 版本号规则

| 类型 | 示例 | 何时使用 |
|------|------|---------|
| **MAJOR** | 2.0.0 → 3.0.0 | 破坏性变更、大重构 |
| **MINOR** | 2.32.0 → 2.33.0 | 新增 agents/commands/skills |
| **PATCH** | 2.32.0 → 2.32.1 | Bug 修复、文档更新 |

---

## 故障排除

### 版本不一致

```
[ERROR] Version mismatch!
  marketplace.json: 2.31.0
  plugin.json:      2.32.0
```

**解决**：使用 `bump-version.ps1` 统一更新，或手动修改两个文件。

### 组件数量不匹配

```
[ERROR] Component counts mismatch
  Actual: Agents=28, Commands=26, Skills=20
  Declared: Agents=28, Commands=26, Skills=17
```

**解决**：更新以下文件中的数量：
- `plugins/compound-engineering/README.md`
- `.claude-plugin/marketplace.json` 的 description
- `plugins/compound-engineering/.claude-plugin/plugin.json` 的 description

---

## 相关文档

- [版本管理策略](VERSION-STRATEGY.md)
- [发布检查清单](../development/VERSIONING.md)
