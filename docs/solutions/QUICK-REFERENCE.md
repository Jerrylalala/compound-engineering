# 预防策略快速参考卡

> 打印此文档，贴在显示器旁边。

## 🚨 提交前必查（3 步）

```powershell
# 1. 版本检查
scripts/check-versions.ps1

# 2. 运行测试
tests/run-all-tests.ps1

# 3. 检查暂存区
git status
```

---

## 🔄 上游同步前必查（2 步）

```powershell
# 1. 验证合并安全性
scripts/validate-upstream-merge.ps1

# 2. 审查上游 commits
git log --oneline HEAD..upstream/main
```

**如果 validate-upstream-merge.ps1 返回错误 → 必须使用选择性合并**

---

## ❌ 绝对禁止

| 禁止项 | 原因 | 解决方案文档 |
|--------|------|--------------|
| SessionStart hooks | Windows 终端阻塞 | sessionstart-hook-prompt-type-not-supported.md |
| `type: "prompt"` hooks | 不被支持 | 同上 |
| Unicode 圆圈数字（①②③） | 终端兼容性 | marketplace-update-failure-and-unicode-display.md |
| `Task(skill-name)` | Skills 不能直接调用 | skill-vs-agent-invocation.md |
| 直接 `git merge upstream/main` | 会删除 fork 文件 | upstream-merge-architectural-analysis-2026-02-10.md |

---

## ✅ 推荐做法

### 版本更新

```powershell
# 自动更新版本号（推荐）
scripts/bump-version.ps1 -BumpType patch
```

### 组件引用前检查

```bash
# 检查是否是 agent
ls plugins/compound-engineering/agents/**/*name*.md

# 检查是否是 skill
ls plugins/compound-engineering/skills/*name*/SKILL.md
```

### 静态内容注入

```
使用 CLAUDE.md（✅）
不使用 SessionStart hooks（❌）
```

---

## 📋 发布检查清单

- [ ] 更新版本号：`scripts/bump-version.ps1`
- [ ] 验证版本一致性：`scripts/check-versions.ps1`
- [ ] 运行所有测试：`tests/run-all-tests.ps1`
- [ ] 更新 CHANGELOG.md
- [ ] 更新 README.md 组件数量
- [ ] 创建 Git tag：`git tag v<version>`
- [ ] 推送：`git push origin main --tags`

---

## 🔍 问题排查流程

```
遇到问题
    ↓
搜索 docs/solutions/
    ↓
检查 CLAUDE.md 规范
    ↓
运行相关测试脚本
    ↓
查看 Git 历史
    ↓
参考 PREVENTION-STRATEGIES.md
```

---

## 📞 快速命令

```powershell
# 版本管理
scripts/check-versions.ps1
scripts/bump-version.ps1 -BumpType patch

# 上游同步
scripts/validate-upstream-merge.ps1
git fetch upstream

# 测试
tests/run-all-tests.ps1
Invoke-Pester tests/version-consistency.test.ps1

# 组件统计
(Get-ChildItem -Recurse plugins/compound-engineering/agents/*.md).Count
(Get-ChildItem -Recurse plugins/compound-engineering/commands/*.md).Count
(Get-ChildItem -Directory plugins/compound-engineering/skills/).Count
```

---

## 🎯 核心原则

1. **版本号必须同步** - marketplace.json = plugin.json
2. **组件引用必须有效** - 无幻影 agent/skill 引用
3. **跨平台兼容** - 无 Unicode 特殊字符
4. **Hook 系统安全** - SessionStart 保持为空
5. **上游同步谨慎** - 使用选择性合并保护 fork 文件

---

**打印日期**：2026-03-11
**文档版本**：v1.0
