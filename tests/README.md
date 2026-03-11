# Compound Engineering Plugin - Test Suite

> 自动化测试套件，用于预防已知问题回归并确保插件质量。

## 快速开始

### 安装 Pester（首次运行）

```powershell
Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
```

### 运行所有测试

```powershell
# 标准模式
powershell -ExecutionPolicy Bypass -File tests/run-all-tests.ps1

# 详细输出模式
powershell -ExecutionPolicy Bypass -File tests/run-all-tests.ps1 -Verbose

# CI 模式（生成 NUnit XML 报告）
powershell -ExecutionPolicy Bypass -File tests/run-all-tests.ps1 -CI
```

### 运行单个测试套件

```powershell
# 版本一致性测试
Invoke-Pester tests/version-consistency.test.ps1

# 组件引用完整性测试
Invoke-Pester tests/component-references.test.ps1

# 跨平台兼容性测试
Invoke-Pester tests/cross-platform.test.ps1

# Hook 系统安全测试
Invoke-Pester tests/hooks.test.ps1

# 上游同步安全测试
Invoke-Pester tests/upstream-sync.test.ps1
```

---

## 测试套件说明

### 1. 版本一致性测试 (`version-consistency.test.ps1`)

**目的**：确保版本号在所有配置文件中同步。

**检查项**：
- ✅ `marketplace.json` 和 `plugin.json` 版本号一致
- ✅ `CHANGELOG.md` 包含当前版本记录
- ✅ 版本号遵循语义化版本格式（X.Y.Z）
- ✅ Fork 身份信息正确（owner, homepage, repository）
- ✅ 组件数量（agents, commands, skills）与声明一致

**相关问题**：
- [marketplace-update-failure-and-unicode-display.md](../docs/solutions/integration-issues/marketplace-update-failure-and-unicode-display.md)

---

### 2. 组件引用完整性测试 (`component-references.test.ps1`)

**目的**：确保所有组件引用（agents, skills, commands）有效。

**检查项**：
- ✅ 所有 `Task()` 调用引用存在的 agents
- ✅ 工作流命令中无幻影 agent 引用
- ✅ Skills 不通过 `Task()` 直接调用
- ✅ 所有 skill 目录包含 `SKILL.md`
- ⚠️ Agent 命名遵循推荐模式（警告级别）

**相关问题**：
- [skill-vs-agent-invocation.md](../docs/solutions/integration-issues/skill-vs-agent-invocation.md)
- [phantom-agent-references-in-workflows.md](../docs/solutions/integration-issues/phantom-agent-references-in-workflows.md)

---

### 3. 跨平台兼容性测试 (`cross-platform.test.ps1`)

**目的**：确保 CLI 输出在不同终端环境下正常显示。

**检查项**：
- ✅ 命令描述中无 Unicode 圆圈数字（①②③）
- ✅ CLI 内容中无 emoji
- ✅ 无特殊 Unicode 符号（⚠️ ✅ ❌）
- ⚠️ 行尾符一致性（LF vs CRLF）
- ✅ Bash 脚本使用正斜杠路径分隔符
- ✅ 工作流描述使用 "Step N:" 格式

**相关问题**：
- [marketplace-update-failure-and-unicode-display.md](../docs/solutions/integration-issues/marketplace-update-failure-and-unicode-display.md)

---

### 4. Hook 系统安全测试 (`hooks.test.ps1`)

**目的**：确保 hooks.json 遵循安全配置模式。

**检查项**：
- ✅ `hooks.json` 文件存在
- ✅ `hooks.json` 有正确的 schema 结构
- ✅ 无 SessionStart hooks（防止终端阻塞）
- ✅ 无 `type: "prompt"` hooks（不被支持）
- ✅ SessionStart 不使用 `type: "command"`（Windows 阻塞）
- ✅ 插件 `CLAUDE.md` 存在（替代 hooks 的推荐方式）

**相关问题**：
- [sessionstart-hook-prompt-type-not-supported.md](../docs/solutions/integration-issues/sessionstart-hook-prompt-type-not-supported.md)

---

### 5. 上游同步安全测试 (`upstream-sync.test.ps1`)

**目的**：确保 fork 特定文件在上游同步后完整保留。

**检查项**：
- ✅ 所有受保护的 fork 文件存在
- ✅ 所有受保护的目录存在
- ✅ Gemini 集成文件完整
- ✅ 自定义工作流命令存在
- ✅ 工作流中无幻影 agent 引用
- ✅ 不引用已移除的 agents
- ✅ `validate-upstream-merge.ps1` 脚本存在
- ✅ 上游合并文档完整

**相关问题**：
- [upstream-merge-architectural-analysis-2026-02-10.md](../docs/solutions/integration-issues/upstream-merge-architectural-analysis-2026-02-10.md)
- [phantom-agent-references-in-workflows.md](../docs/solutions/integration-issues/phantom-agent-references-in-workflows.md)

---

## 开发工作流集成

### 提交前检查

```powershell
# 1. 运行所有测试
tests/run-all-tests.ps1

# 2. 检查版本一致性
scripts/check-versions.ps1

# 3. 如果测试通过，提交代码
git add .
git commit -m "你的提交信息"
```

### 上游同步前检查

```powershell
# 1. 验证上游合并安全性
scripts/validate-upstream-merge.ps1

# 2. 运行上游同步测试
Invoke-Pester tests/upstream-sync.test.ps1

# 3. 如果安全，执行选择性合并
# 参考：docs/solutions/integration-issues/upstream-merge-architectural-analysis-2026-02-10.md
```

### 发布前检查

```powershell
# 1. 更新版本号
scripts/bump-version.ps1 -BumpType patch

# 2. 运行完整测试套件
tests/run-all-tests.ps1

# 3. 验证版本一致性
scripts/check-versions.ps1

# 4. 如果全部通过，创建 tag 并推送
git tag v<version>
git push origin main --tags
```

---

## 测试结果解读

### 成功输出示例

```
========================================
  Test Summary
========================================

Total Tests:  42
Passed:       42
Failed:       0
Skipped:      0
Duration:     3.5 seconds

✅ ALL TESTS PASSED

========================================
```

### 失败输出示例

```
========================================
  Test Summary
========================================

Total Tests:  42
Passed:       40
Failed:       2
Skipped:      0
Duration:     3.8 seconds

❌ TESTS FAILED

Failed tests:
  - Version Number Consistency.marketplace.json and plugin.json versions match
    Expected '2.40.1', but got '2.40.0'
  - Component Reference Integrity.All Task() calls reference existing agents
    Task(rails-turbo-expert) references non-existent agent

========================================
```

---

## 添加新测试

### 1. 创建新测试文件

```powershell
# 在 tests/ 目录创建新文件
New-Item tests/my-new-test.test.ps1
```

### 2. 使用 Pester 语法编写测试

```powershell
BeforeAll {
    # 初始化代码
}

Describe "My Test Suite" {
    It "Should pass this test" {
        $result = 1 + 1
        $result | Should -Be 2
    }
}
```

### 3. 添加到测试运行器

编辑 `tests/run-all-tests.ps1`，在 `$testFiles` 数组中添加新文件：

```powershell
$testFiles = @(
    "tests/version-consistency.test.ps1",
    "tests/component-references.test.ps1",
    "tests/cross-platform.test.ps1",
    "tests/hooks.test.ps1",
    "tests/upstream-sync.test.ps1",
    "tests/my-new-test.test.ps1"  # 新增
)
```

---

## 常见问题

### Q: 测试失败了怎么办？

**A**: 根据失败信息定位问题：

1. **版本不一致**：运行 `scripts/bump-version.ps1` 同步版本号
2. **幻影 agent 引用**：检查工作流文件，移除不存在的 agent 引用
3. **Unicode 字符问题**：替换为 ASCII 兼容格式（如 "Step 1:"）
4. **Hook 配置问题**：确保 `hooks.json` 的 `hooks` 字段为空对象 `{}`

### Q: 如何跳过某个测试？

**A**: 在测试文件中使用 `-Skip` 参数：

```powershell
It "This test is skipped" -Skip {
    # 测试代码
}
```

### Q: 如何只运行特定的测试？

**A**: 使用 Pester 的 `-FullName` 参数：

```powershell
Invoke-Pester tests/version-consistency.test.ps1 -FullName "*marketplace.json and plugin.json*"
```

---

## 相关文档

- [预防策略与最佳实践](../docs/solutions/PREVENTION-STRATEGIES.md)
- [版本管理预防策略](../docs/zh-CN/VERSION-STRATEGY.md)
- [上游同步指南](../docs/zh-CN/SYNC.md)
- [脚本使用说明](../docs/zh-CN/SCRIPTS.md)

---

## 贡献指南

发现新的可测试问题时：

1. 在 `docs/solutions/integration-issues/` 创建问题文档
2. 在 `tests/` 创建对应的测试用例
3. 更新 `docs/solutions/PREVENTION-STRATEGIES.md`
4. 更新本 README 文件

---

**最后更新**：2026-03-11
