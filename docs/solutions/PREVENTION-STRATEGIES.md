---
title: "Compound Engineering Plugin 预防策略与最佳实践"
category: prevention
tags: [best-practices, prevention, testing, validation, fork-management]
date_created: 2026-03-11
status: living-document
---

# Compound Engineering Plugin 预防策略与最佳实践

> **目标**：通过系统化的预防措施，避免重复发生已知问题，提升插件开发与维护质量。

## 目录

1. [版本管理预防](#1-版本管理预防)
2. [上游同步预防](#2-上游同步预防)
3. [组件引用预防](#3-组件引用预防)
4. [跨平台兼容性预防](#4-跨平台兼容性预防)
5. [Hook 系统预防](#5-hook-系统预防)
6. [文档同步预防](#6-文档同步预防)
7. [自动化测试策略](#7-自动化测试策略)
8. [开发工作流检查清单](#8-开发工作流检查清单)

---

## 1. 版本管理预防

### 问题来源
- [marketplace-update-failure-and-unicode-display.md](integration-issues/marketplace-update-failure-and-unicode-display.md)
- [VERSION-STRATEGY.md](../zh-CN/VERSION-STRATEGY.md)

### 预防措施

#### 1.1 release metadata 同步

**安装 Git Hook（一次性）**
```powershell
# 复制 pre-commit hook
copy scripts\pre-commit .git\hooks\pre-commit

# 验证安装
Test-Path .git\hooks\pre-commit
```

**修改发布元数据后使用 release 脚本**
```bash
bun run release:sync-metadata
bun run release:validate
```

#### 1.2 版本号同步检查点

| 文件 | 字段 | 必须同步 |
|------|------|----------|
| `.github/.release-please-manifest.json` | component versions | ✅ |
| `plugins/compound-engineering/.claude-plugin/plugin.json` | `version` / `description` | ✅ |
| `plugins/compound-engineering/.cursor-plugin/plugin.json` | `version` / `description` | ✅ |
| `.claude-plugin/marketplace.json` / `.cursor-plugin/marketplace.json` | marketplace metadata | ✅ |
| `plugins/compound-engineering/README.md` | 组件数量与公开能力描述 | ✅ |

#### 1.3 快速验证命令

```powershell
# 轻量身份和版本格式检查
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1
```

```bash
# 权威 release metadata 验证
bun run release:validate
```

#### 1.4 测试用例

**测试脚本：`tests/version-consistency.test.ps1`**
```powershell
Describe "Version Consistency" {
    It "release metadata validation passes" {
        bun run release:validate
        $LASTEXITCODE | Should -Be 0
    }
}
```

---

## 2. 上游同步预防

### 问题来源
- [upstream-merge-architectural-analysis-2026-02-10.md](integration-issues/upstream-merge-architectural-analysis-2026-02-10.md)
- [phantom-agent-references-in-workflows.md](integration-issues/phantom-agent-references-in-workflows.md)

### 预防措施

#### 2.1 同步前验证（强制）

**每次同步前运行验证脚本**
```powershell
# 检查上游合并风险
powershell -ExecutionPolicy Bypass -File scripts/validate-upstream-merge.ps1

# 如果返回错误，查看详细信息
powershell -ExecutionPolicy Bypass -File scripts/validate-upstream-merge.ps1 -Verbose
```

#### 2.2 受保护的 Fork 文件清单

**Tier 1 - 核心功能（绝对不能删除）**
```
plugins/compound-engineering/commands/codex.md
plugins/compound-engineering/commands/gemini.md
plugins/compound-engineering/commands/workflows/load.md
plugins/compound-engineering/commands/workflows/save.md
plugins/compound-engineering/commands/workflows/sync-upstream.md
plugins/compound-engineering/hooks/
src/converters/claude-to-gemini.ts
src/targets/gemini.ts
src/types/gemini.ts
src/utils/filter-claude-code-only.ts
```

**Tier 2 - 高价值（中文化与自动化）**
```
docs/zh-CN/
docs/solutions/
scripts/*.ps1
scripts/*.sh
```

**Tier 3 - 运营数据（可恢复但有价值）**
```
docs/sync-reports/
docs/brainstorms/
docs/plans/
skills-custom/
```

#### 2.3 上游同步决策树

```
收到上游更新通知
    ↓
运行 validate-upstream-merge.ps1
    ↓
    ├─ 无保护文件冲突 ──→ 可以考虑 cherry-pick
    │                      ↓
    │                   审查上游 commits
    │                      ↓
    │                   选择性 cherry-pick
    │
    └─ 有保护文件冲突 ──→ 必须使用选择性合并
                           ↓
                        参考 upstream merge 架构分析
                           ↓
                        手动整合 + 文档记录
```

#### 2.4 组件引用完整性检查

**检查工作流中引用的 agents 是否存在**
```bash
# 提取所有引用的 agents
grep -h "Task [a-z-]*(" plugins/compound-engineering/commands/workflows/*.md | \
  sed 's/.*Task \([a-z-]*\).*/\1/' | sort -u > /tmp/referenced-agents.txt

# 提取实际存在的 agents
ls plugins/compound-engineering/agents/**/*.md | \
  xargs -n1 basename | sed 's/.md//' | sort -u > /tmp/existing-agents.txt

# 找出幻影引用
comm -23 /tmp/referenced-agents.txt /tmp/existing-agents.txt
```

**预期输出：空（无幻影引用）**

#### 2.5 测试用例

**测试脚本：`tests/upstream-sync.test.ps1`**
```powershell
Describe "Upstream Sync Safety" {
    It "Protected fork files exist" {
        $protectedFiles = @(
            "plugins/compound-engineering/commands/gemini.md",
            "src/converters/claude-to-gemini.ts",
            "docs/zh-CN/INSTALL.md"
        )

        foreach ($file in $protectedFiles) {
            Test-Path $file | Should -Be $true
        }
    }

    It "No phantom agent references in workflows" {
        $workflowFiles = Get-ChildItem plugins/compound-engineering/commands/workflows/*.md
        $agentFiles = Get-ChildItem plugins/compound-engineering/agents/**/*.md

        $referencedAgents = $workflowFiles | Select-String "Task ([a-z-]+)\(" -AllMatches |
            ForEach-Object { $_.Matches.Groups[1].Value } | Sort-Object -Unique

        $existingAgents = $agentFiles | ForEach-Object { $_.BaseName } | Sort-Object -Unique

        $phantoms = $referencedAgents | Where-Object { $_ -notin $existingAgents }

        $phantoms.Count | Should -Be 0
    }
}
```

---

## 3. 组件引用预防

### 问题来源
- [skill-vs-agent-invocation.md](integration-issues/skill-vs-agent-invocation.md)
- [phantom-agent-references-in-workflows.md](integration-issues/phantom-agent-references-in-workflows.md)

### 预防措施

#### 3.1 组件类型识别规则

| 组件类型 | 位置 | 调用方式 | 文件标识 |
|----------|------|----------|----------|
| **Agent** | `agents/` | `Task(agent-name)` | `*.md` 文件 |
| **Skill** | `skills/` | `skill: skill-name` | `SKILL.md` 文件 |
| **Command** | `commands/` | `/command-name` | `*.md` 文件 |

#### 3.2 调用前检查清单

**在代码中引用组件前，必须验证：**

```bash
# 1. 检查是否是 agent
ls plugins/compound-engineering/agents/**/*name*.md

# 2. 检查是否是 skill
ls plugins/compound-engineering/skills/*name*/SKILL.md

# 3. 检查是否是 command
ls plugins/compound-engineering/commands/**/*name*.md
```

#### 3.3 命名约定（推荐）

**Agents（动作执行者）**
- `xxx-reviewer` - 审查类
- `xxx-analyzer` - 分析类
- `xxx-specialist` - 专家类
- `xxx-guardian` - 守护类

**Skills（知识流程）**
- `xxx-development` - 开发流程
- `xxx-debugging` - 调试流程
- `xxx-review` - 审查流程（名词形式）

#### 3.4 测试用例

**测试脚本：`tests/component-references.test.ps1`**
```powershell
Describe "Component References" {
    It "All Task() calls reference existing agents" {
        $allMdFiles = Get-ChildItem -Recurse plugins/compound-engineering/**/*.md

        $taskCalls = $allMdFiles | Select-String "Task\(([a-z-]+)\)" -AllMatches |
            ForEach-Object { $_.Matches.Groups[1].Value } | Sort-Object -Unique

        $existingAgents = Get-ChildItem plugins/compound-engineering/agents/**/*.md |
            ForEach-Object { $_.BaseName } | Sort-Object -Unique

        foreach ($task in $taskCalls) {
            $existingAgents | Should -Contain $task
        }
    }

    It "Skill references use correct format" {
        # Skills 应该通过 'skill: skill-name' 或在 Task 描述中引用
        # 不应该直接 Task(skill-name)

        $skillNames = Get-ChildItem -Directory plugins/compound-engineering/skills/ |
            ForEach-Object { $_.Name }

        $allMdFiles = Get-ChildItem -Recurse plugins/compound-engineering/**/*.md
        $taskCalls = $allMdFiles | Select-String "Task\(([a-z-]+)\)" -AllMatches |
            ForEach-Object { $_.Matches.Groups[1].Value }

        # Task() 调用不应该直接引用 skill 名称
        $invalidCalls = $taskCalls | Where-Object { $_ -in $skillNames }

        $invalidCalls.Count | Should -Be 0
    }
}
```

---

## 4. 跨平台兼容性预防

### 问题来源
- [marketplace-update-failure-and-unicode-display.md](integration-issues/marketplace-update-failure-and-unicode-display.md)

### 预防措施

#### 4.1 字符编码规范

**禁止使用的 Unicode 字符**
```
❌ 圆圈数字：①②③④⑤⑥⑦⑧⑨⑩
❌ 特殊符号：⚠️ ✅ ❌（在 CLI 输出中）
❌ Emoji：🚀 🎉 💡（在命令描述中）
```

**推荐使用的替代方案**
```
✅ ASCII 序号：Step 1:, Step 2:, Step 3:
✅ 文本标记：[OK], [ERROR], [WARN]
✅ 纯文本描述：Success, Failed, Warning
```

#### 4.2 终端兼容性测试

**测试环境清单**
- [ ] Windows PowerShell 5.1
- [ ] Windows PowerShell 7+
- [ ] Windows CMD
- [ ] Git Bash (MINGW64)
- [ ] WSL2 (Ubuntu)

**测试命令**
```powershell
# 测试命令描述显示
claude --plugin-dir "..." --help

# 测试工作流输出
/workflows:brainstorm
/workflows:plan
```

#### 4.3 测试用例

**测试脚本：`tests/cross-platform.test.ps1`**
```powershell
Describe "Cross-Platform Compatibility" {
    It "No Unicode circle numbers in command descriptions" {
        $commandFiles = Get-ChildItem -Recurse plugins/compound-engineering/commands/*.md

        $circleNumbers = $commandFiles | Select-String "[\u2460-\u2473]"

        $circleNumbers.Count | Should -Be 0
    }

    It "No emoji in CLI-facing content" {
        $cliFiles = Get-ChildItem -Recurse plugins/compound-engineering/commands/*.md

        # 检测常见 emoji 范围
        $emojis = $cliFiles | Select-String "[\u1F300-\u1F9FF]"

        $emojis.Count | Should -Be 0
    }
}
```

---

## 5. Hook 系统预防

### 问题来源
- [sessionstart-hook-prompt-type-not-supported.md](integration-issues/sessionstart-hook-prompt-type-not-supported.md)

### 预防措施

#### 5.1 Hook 配置铁律

**绝对禁止的配置**
```json
// ❌ 禁止：SessionStart 使用 type: "prompt"
{
  "hooks": {
    "SessionStart": [
      { "type": "prompt", "prompt": "..." }  // 不被支持
    ]
  }
}

// ❌ 禁止：SessionStart 使用 type: "command"（Windows 会卡终端）
{
  "hooks": {
    "SessionStart": [
      { "type": "command", "command": "..." }  // Windows 阻塞 stdin
    ]
  }
}
```

**正确的配置**
```json
// ✅ 正确：SessionStart 保持为空
{
  "description": "Compound Engineering Plugin Hooks",
  "hooks": {}
}
```

#### 5.2 静态内容注入方式

**使用插件 CLAUDE.md 替代 hooks**
```
plugins/compound-engineering/CLAUDE.md
    ↓
插件启用时自动加载为系统上下文
    ↓
无需 hooks，无跨平台问题
```

#### 5.3 上游整合时的 Hook 检查

**每次上游整合涉及 hooks.json 时，必须：**

1. 对照 `sessionstart-hook-prompt-type-not-supported.md`
2. 确认 `hooks.json` 的 `hooks` 字段为空对象 `{}`
3. 拒绝任何 SessionStart hook（无论 type）

#### 5.4 测试用例

**测试脚本：`tests/hooks.test.ps1`**
```powershell
Describe "Hook System Safety" {
    It "hooks.json has no SessionStart hooks" {
        $hooksFile = "plugins/compound-engineering/hooks/hooks.json"

        if (Test-Path $hooksFile) {
            $hooks = Get-Content $hooksFile | ConvertFrom-Json

            if ($hooks.hooks.PSObject.Properties.Name -contains "SessionStart") {
                $hooks.hooks.SessionStart.Count | Should -Be 0
            }
        }
    }

    It "hooks.json uses correct schema format" {
        $hooksFile = "plugins/compound-engineering/hooks/hooks.json"

        if (Test-Path $hooksFile) {
            $hooks = Get-Content $hooksFile | ConvertFrom-Json

            # 必须有 description 和 hooks 字段
            $hooks.PSObject.Properties.Name | Should -Contain "description"
            $hooks.PSObject.Properties.Name | Should -Contain "hooks"
        }
    }
}
```

---

## 6. 文档同步预防

### 预防措施

#### 6.1 文档更新触发条件

| 修改类型 | 必须更新的文档 | 检查方式 |
|----------|----------------|----------|
| 新增 Agent | README / plugin README / 支持矩阵 | `bun run release:validate` |
| 新增 Command | README / 安装说明 / 支持矩阵 | `bun run release:validate` |
| 新增 Skill | README / plugin README / skill 参数表 | `bash scripts/check-feature-integrity.sh` |
| 修改工作流 | README / workflow 文档 / 相关解决方案文档 | `mkdocs build --strict` |
| Bug 修复 | 相关解决方案文档（如适用） | 对应测试 + release validate |

#### 6.2 Release notes 规则

公开 release notes 由 release-please 生成。普通 PR 不手写 `CHANGELOG.md` 条目；通过 conventional commit 标题表达变更类型和范围。

#### 6.3 测试用例

**测试脚本：`tests/documentation.test.ps1`**
```powershell
Describe "Documentation Sync" {
    It "Component counts in README match actual counts" {
        $readme = Get-Content plugins/compound-engineering/README.md -Raw

        $agentCount = (Get-ChildItem -Recurse plugins/compound-engineering/agents/*.md).Count
        $commandCount = (Get-ChildItem -Recurse plugins/compound-engineering/commands/*.md).Count
        $skillCount = (Get-ChildItem -Directory plugins/compound-engineering/skills/).Count

        $readme | Should -Match "$agentCount agents?"
        $readme | Should -Match "$commandCount commands?"
        $readme | Should -Match "$skillCount skills?"
    }
}
```

---

## 7. 自动化测试策略

### 7.1 测试框架选择

**推荐：Pester（PowerShell 测试框架）**
```powershell
# 安装 Pester
Install-Module -Name Pester -Force -SkipPublisherCheck

# 运行所有测试
Invoke-Pester tests/
```

### 7.2 测试目录结构

```
tests/
├── version-consistency.test.ps1      # 版本一致性测试
├── upstream-sync.test.ps1            # 上游同步安全测试
├── component-references.test.ps1     # 组件引用完整性测试
├── cross-platform.test.ps1           # 跨平台兼容性测试
├── hooks.test.ps1                    # Hook 系统安全测试
├── documentation.test.ps1            # 文档同步测试
└── integration.test.ps1              # 集成测试
```

### 7.3 CI/CD 集成（未来）

**GitHub Actions 工作流示例**
```yaml
name: Plugin Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Pester Tests
        shell: powershell
        run: |
          Install-Module -Name Pester -Force -SkipPublisherCheck
          Invoke-Pester tests/ -OutputFormat NUnitXml -OutputFile test-results.xml
      - name: Publish Test Results
        uses: EnricoMi/publish-unit-test-result-action@v2
        if: always()
        with:
          files: test-results.xml
```

---

## 8. 开发工作流检查清单

### 8.1 开发前检查

- [ ] 拉取最新代码：`git pull origin main`
- [ ] 检查上游更新：`git fetch upstream`
- [ ] 验证版本一致性：`scripts/check-versions.ps1`
- [ ] 确认组件数量正确

### 8.2 开发中检查

- [ ] 引用组件前验证存在性（agents/skills/commands）
- [ ] 避免使用 Unicode 特殊字符
- [ ] 遵循命名约定
- [ ] 及时提交小步骤（避免大批量修改）

### 8.3 提交前检查

- [ ] 运行 release metadata 验证：`bun run release:validate`
- [ ] 运行相关测试：`bun test`
- [ ] 更新相关文档（如有）
- [ ] 检查 Git 暂存区：`git status`
- [ ] 使用中文 commit message

### 8.4 发布前检查

- [ ] release PR 已由 release-please 创建或更新
- [ ] release PR 中组件版本、tag 和 release notes 正确
- [ ] `bun run release:validate` 通过
- [ ] `bun test` 通过
- [ ] `mkdocs build --strict` 通过
- [ ] 如涉及 npm，按 `docs/zh-CN/PUBLISHING.md` 做 pack/install smoke test

### 8.5 上游同步前检查

- [ ] 运行上游合并验证：`scripts/validate-upstream-merge.ps1`
- [ ] 审查上游 commits：`git log --oneline HEAD..upstream/main`
- [ ] 识别受保护文件冲突
- [ ] 准备选择性合并策略
- [ ] 参考 `docs/solutions/integration-issues/upstream-merge-architectural-analysis-2026-02-10.md`

---

## 9. 快速参考

### 9.1 常用命令速查

```powershell
# 版本管理
scripts/check-versions.ps1                    # 检查版本一致性
bun run release:validate                      # 验证 release metadata
bun run release:sync-metadata                 # 同步 release metadata

# 上游同步
scripts/validate-upstream-merge.ps1          # 验证上游合并安全性
git fetch upstream                           # 拉取上游更新
git log --oneline HEAD..upstream/main        # 查看上游新 commits

# 组件检查
ls plugins/compound-engineering/agents/**/*.md | Measure-Object    # 统计 agents
ls plugins/compound-engineering/commands/**/*.md | Measure-Object  # 统计 commands
ls plugins/compound-engineering/skills/ | Measure-Object           # 统计 skills

# 测试
Invoke-Pester tests/                         # 运行所有测试
Invoke-Pester tests/version-consistency.test.ps1  # 运行单个测试
```

### 9.2 问题排查流程

```
遇到问题
    ↓
1. 搜索 docs/solutions/ 是否有相关文档
    ↓
2. 检查 CLAUDE.md 是否有相关规范
    ↓
3. 运行相关测试脚本验证
    ↓
4. 查看 Git 历史是否有类似修复
    ↓
5. 参考本文档的预防策略
    ↓
6. 解决后创建新的解决方案文档
```

---

## 10. 相关文档

| 文档 | 用途 |
|------|------|
| [VERSION-STRATEGY.md](../zh-CN/VERSION-STRATEGY.md) | 版本管理详细策略 |
| [SYNC.md](../zh-CN/SYNC.md) | 上游同步操作指南 |
| [SCRIPTS.md](../zh-CN/SCRIPTS.md) | 脚本使用说明 |
| [upstream-merge-architectural-analysis-2026-02-10.md](integration-issues/upstream-merge-architectural-analysis-2026-02-10.md) | 上游合并架构分析 |
| [integration-issues/](integration-issues/) | 已知问题解决方案库 |

---

## 修订历史

| 日期 | 修改内容 | 作者 |
|------|----------|------|
| 2026-03-11 | 初始版本，整合所有已知预防策略 | Claude Opus 4.6 |
