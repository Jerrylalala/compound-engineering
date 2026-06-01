# 脚本使用说明

本项目提供自动化脚本来简化版本管理和发布流程。

## 脚本列表

| 脚本 | 用途 | 平台 |
|------|------|------|
| `check-versions.ps1` | 检查版本一致性 | Windows |
| `check-versions.sh` | 检查版本一致性 | Linux/macOS |
| `bump-version.ps1` | 旧版手工版本工具，常规开发不推荐 | Windows |
| `pre-commit` | Git 提交前检查 | 通用 |

---

## check-versions（版本检查）

检查插件清单是否存在、`plugin.json` 版本号格式是否正确、仓库身份信息是否指向当前 fork，并提示组件数量是否与描述同步。

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
  plugin.json: 2.32.0
[OK] Version (plugin.json): 2.32.0
[INFO] Validating version format...
[OK] Version format valid: 2.32.0

[INFO] Checking component counts...
  Actual: Agents=28, Commands=26, Skills=20
  Declared: Agents=28, Commands=26, Skills=20
[OK] Component counts match

========================================
  ALL CHECKS PASSED
========================================
```

---

## bump-version（旧版手工版本工具）

自动更新旧版手工版本文件。当前常规开发不推荐手动 bump 版本；正式发布由 release automation 处理。只有在维护历史流程或修复旧版脚本时才应使用。

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
[ERROR] Release metadata drift detected:
- plugins/compound-engineering/.cursor-plugin/plugin.json
```

**解决**：常规开发不要手动修改 release-owned 版本。先运行 `bun run release:sync-metadata`，再运行 `bun run release:validate`；如果仍失败，再检查 release-please 配置和 manifest。

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
- [发布检查清单](https://github.com/Jerrylalala/compound-engineering/blob/main/docs/development/VERSIONING.md)
