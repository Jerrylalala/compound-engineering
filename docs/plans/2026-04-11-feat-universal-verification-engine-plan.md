---
title: "feat: 通用自动化验证引擎——扩展 [V] Layer 2"
type: feat
status: completed
date: 2026-04-11
origin: docs/brainstorms/2026-04-11-universal-verification-engine-requirements.md
---

# feat: 通用自动化验证引擎

## Overview

扩展 ce:work 的 `[V]` 四层验证，将 Layer 2 从「仅浏览器 UI 测试」扩展为「根据项目类型自动选择验证策略」。核心改动：新增 TEST_COMMAND 自动推导 + Layer 2 多路由 + 修复循环增强。

(see origin: docs/brainstorms/2026-04-11-universal-verification-engine-requirements.md)

## Problem Frame

当前 `[V]` 模式的 Layer 2 仅支持前端浏览器测试。非前端项目（Python/Rust/CLI/API）跑 `ce:work [V]` 后 Layer 2 直接 skip，用户仍需手动验证。独立开发者期望一条命令覆盖所有项目类型的自动验证。

## Requirements Trace

- R1-R6: TEST_COMMAND 检测与持久化（Unit 1）
- R7-R9: Layer 2 通用验证路由（Unit 2）
- R10-R12: 测试输出解析（Unit 2）
- R13-R18: 自动修复循环增强（Unit 3）
- R19-R27: 安全约束与进程管理（Unit 2, 3）
- R28-R30: 设计图对比集成（Unit 4）
- R31-R33: Plan 测试场景结构化（Unit 5）

## Scope Boundaries

- 不做自动安装依赖工具（pytest/cargo 等），只提示安装命令
- 不做自动创建/删除测试数据库
- 不做所有 API 端点自动发现，只测 plan 中明确的验收条件
- 不做跨平台 shell 兼容层（TEST_COMMAND 就是一条命令）
- 不做模糊断言自动验证
- 不改现有 Layer 0/1/3 的核心逻辑

## Key Technical Decisions

- **TEST_COMMAND 与 START_COMMAND 并行推导**：同一 Phase -1.5 阶段，共用 Level 1 缓存读取和 Level 3b 持久化逻辑。START_COMMAND 看 dev/start scripts，TEST_COMMAND 看 test script（see origin: Key Decisions #1）
- **维持现有 2 轮验证循环结构**：不改 `verification_rounds` 语义。在 Layer 内部增加第 3 次「仅诊断」模式（需求 R16 的实现方式）
- **Layer 2 语义扩展**：从「浏览器验证」变为「项目类型特定验证」，浏览器测试变为其中一个分支
- **npm 空 test 排除**：`"echo \"Error: no test specified\" && exit 1"` 不视为有效 TEST_COMMAND（R6，避免假失败）

## Open Questions

### Resolved During Planning

- **TEST_COMMAND 与 START_COMMAND 如何共存？** → 同一 Phase -1.5 并行推导，Level 3 合并为一次用户交互
- **修复轮次 2 轮 vs 3 轮？** → 维持 2 轮验证循环，Layer 内部重试增加第 3 次「仅诊断不修复」

### Deferred to Implementation

- Layer 0 当前从 CLAUDE.md 手动提取 build/test 命令的逻辑，是否可被 TEST_COMMAND 自动推导完全替代？执行时对比决定
- API endpoint 验证的 curl 请求模板格式，执行时参考 Layer 1 现有结构确定

---

## Implementation Units

- [ ] **Unit 1: TEST_COMMAND 环境指纹扩展**

**Goal:** 在 Phase -1.5 中新增 TEST_COMMAND 推导逻辑，与 START_COMMAND 并列

**Requirements:** R1, R2, R3, R4, R5, R6

**Dependencies:** 无

**Files:**
- Modify: `plugins/compound-engineering/skills/ce-work/SKILL.md`（Phase -1.5 区域，约第 84-202 行）

**Approach:**

在现有 Phase -1.5 环境指纹的决策树中，为 TEST_COMMAND 新增并行推导路径：

Level 1（读缓存）：搜索 `<!-- ce-work-test-command: X -->`，逻辑与 START_COMMAND 的 Level 1 一致（含 source 区分 + 漂移校验）

Level 2（动态推导）：新增 TEST_COMMAND 推导优先级表：

| 优先级 | 匹配条件 | 推导结果 |
|--------|---------|---------|
| 1 | package.json scripts.test 存在且非 npm 默认空命令 | `<PKG_RUN> test` |
| 2 | Makefile 或 Justfile 有 `test:` target | `make test` / `just test` |
| 3 | pyproject.toml 有 `[tool.pytest]` 或 pytest.ini 存在 | `pytest` |
| 4 | Cargo.toml 存在 | `cargo test` |
| 5 | go.mod 存在 | `go test ./...` |
| 6 | 无法推导 | 询问用户 |

npm 默认空 test 排除规则：若 scripts.test 精确匹配 `"echo \"Error: no test specified\" && exit 1"`，视为不存在

Level 3（询问用户）：与 START_COMMAND 合并为一次交互：
> 检测到启动命令：`X`，测试命令：`Y`，对吗？
> 1. 都对
> 2. 修改测试命令
> 3. 修改启动命令
> 4. 都不对

Level 3b（写入 CLAUDE.md）：新增三行注释：
```
<!-- ce-work-test-command: <command> -->
<!-- ce-work-test-command-source: auto-detected|user-provided -->
<!-- ce-work-test-command-updated: YYYY-MM-DD -->
```

Level 4（校验）：与 START_COMMAND 格式校验一致（防 `-->` 注入 + script 存在性检查）

漂移检测：与 START_COMMAND 共用触发条件（package.json 被修改时），重新推导 TEST_COMMAND 并比对

Monorepo 处理：根 package.json 有 scripts.test → 用根命令；否则根据 ce:work 当前 Unit 的 Files 列表定位子包

**Patterns to follow:**
- Phase -1.5 START_COMMAND 推导逻辑（同文件，直接参考上方结构）

**Test scenarios:**
- Given: package.json 有 `scripts.test: "vitest"` + pnpm-lock.yaml 存在; When: Phase -1.5 执行; Then: TEST_COMMAND = `pnpm test`
- Given: package.json scripts.test 为 npm 默认空命令; When: Phase -1.5 执行; Then: TEST_COMMAND 跳过 Level 2，继续 Level 3-6
- Given: Cargo.toml 存在，无 package.json; When: Phase -1.5 执行; Then: TEST_COMMAND = `cargo test`
- Given: CLAUDE.md 已有 `<!-- ce-work-test-command: pytest -->` + source: user-provided; When: Phase -1.5 执行; Then: 直接使用 pytest，不重新推导
- Given: CLAUDE.md 已有 auto-detected TEST_COMMAND，但 package.json scripts.test 已改变; When: Phase -1.5 执行; Then: 检测漂移，询问用户是否更新

**Verification:**
- Phase -1.5 输出包含 TEST_COMMAND 宣告
- CLAUDE.md 被写入 ce-work-test-command 注释
- 漂移检测在 package.json 修改后触发

---

- [ ] **Unit 2: Layer 2 通用验证路由**

**Goal:** 将 Layer 2 从「仅浏览器」扩展为多路由：前端浏览器 / 非前端 TEST_COMMAND / CLI 附加 / API 附加

**Requirements:** R7, R8, R9, R10, R11, R12, R19, R20, R21, R22, R23, R24, R25, R26, R27

**Dependencies:** Unit 1（TEST_COMMAND 已推导完成）

**Files:**
- Modify: `plugins/compound-engineering/skills/ce-work/SKILL.md`（Phase 3.5.1 触发判断 + Phase 3.5.2 Layer 2 执行体）

**Approach:**

**Phase 3.5.1 触发判断扩展**：修改 Layer 2 触发表，从二分法变为多路由：

| 触发信号 | Layer 2 路由 |
|---------|-------------|
| 前端关键词 + .tsx/.vue/.html/.css 变更 | 浏览器测试（现有逻辑不变） |
| TEST_COMMAND 存在且非空 | 跑 TEST_COMMAND |
| CLI 项目（有 argparse/clap/commander + plan 有 CLI 验收条件） | CLI 附加验证 |
| API 项目（有路由文件 + plan 有 API 验收条件） | API 附加验证（启动服务 + curl） |

优先级：浏览器 > API > CLI > TEST_COMMAND。可叠加（前端项目同时跑浏览器 + TEST_COMMAND）

**Layer 2 执行体新增非前端分支**：

```
Layer 2 执行：
  ├─ 路由 A：浏览器测试（现有逻辑不变）
  │
  ├─ 路由 B：TEST_COMMAND 验证
  │   1. 安全检查（R19-R22）：
  │      - 扫描 .env 中 DATABASE_URL / API key 是否指向生产
  │      - 检查 TEST_COMMAND 不含 migration 命令
  │   2. 执行 TEST_COMMAND（Bash）
  │   3. 解析输出（R10-R12）：
  │      - 提取通过/失败/跳过数
  │      - 检测空跑模式（"0 tests" / "no tests collected"）
  │      - 区分环境错误 vs 代码错误
  │   4. 结果 → layers.layer2 = pass/fail/skip
  │
  ├─ 路由 C：CLI 附加验证
  │   1. 跑 --help → 验证可执行且无崩溃
  │   2. 跑 plan 中指定的典型输入 → 验证退出码 + stdout 包含预期
  │
  └─ 路由 D：API 附加验证
      1. 启动服务（用 START_COMMAND）
      2. 等待端口就绪（最多 30s）
      3. 跑 plan 中指定的 curl 验证
      4. 杀掉服务进程
```

**进程管理**（R23-R27）：

所有启动的进程写入 `$TMPDIR/ce-verify-$SESSION_ID/pids`：
- trap EXIT 兜底清理
- 300s 超时硬杀
- 清理后端口扫描兜底
- Windows 适配：`taskkill /F /PID` + `netstat -ano | findstr :<PORT>`

**测试输出解析**（R10-R12）：

解析策略（按测试框架）：
- jest/vitest：匹配 `Tests: N passed, M failed`
- pytest：匹配 `N passed, M failed` 或 `no tests ran`
- cargo test：匹配 `test result: ok. N passed; M failed`
- go test：匹配 `ok` / `FAIL`
- 通用 fallback：退出码 0 = pass，非 0 = fail + 输出原始 stderr

**Patterns to follow:**
- Phase 3.5.2 Layer 2 浏览器测试现有逻辑（同文件，直接参考）
- Phase -1.5 Level 4 校验逻辑（安全检查模式）

**Test scenarios:**
- Given: Python 项目，TEST_COMMAND = `pytest`，有 3 个测试文件; When: Layer 2 执行; Then: 跑 pytest，输出 "3 passed, 0 failed"，layers.layer2 = pass
- Given: Node 项目，TEST_COMMAND = `npm test`，测试有 1 个失败; When: Layer 2 执行; Then: 输出失败详情，layers.layer2 = fail，进入修复循环
- Given: TEST_COMMAND 为空（无法推导）; When: Layer 2 触发判断; Then: layers.layer2 = skip，记录原因
- Given: .env 中 DATABASE_URL 含 `amazonaws.com`; When: 安全检查; Then: 警告并阻止执行
- Given: pytest 跑完输出 "no tests ran"; When: 输出解析; Then: 标记为警告（空跑），不视为 pass
- Given: Windows 环境，启动了端口 3000 的服务; When: 测试结束; Then: 用 taskkill 清理，netstat 验证端口释放

**Verification:**
- 非前端项目的 Layer 2 不再 skip，而是跑 TEST_COMMAND
- 安全检查在生产环境标志存在时阻止执行
- 进程清理后无残留端口占用

---

- [ ] **Unit 3: 自动修复循环增强**

**Goal:** 在 Layer 内部重试中增加第 3 次「仅诊断不修复」模式，增加回滚保护

**Requirements:** R13, R14, R15, R16, R17, R18

**Dependencies:** Unit 2（Layer 2 路由已实现）

**Files:**
- Modify: `plugins/compound-engineering/skills/ce-work/SKILL.md`（Phase 3.5.2 Layer 内部重试逻辑）

**Approach:**

现有 Layer 0 已有 `layer0_inner_retries`（最多 3 次）。扩展为所有 Layer 通用的修复循环：

```
Layer 内部重试（通用模式，适用于 Layer 0/2）：
  第 1 次重试：完整诊断 + 修复 + 重跑（不限修改范围）
  第 2 次重试：缩小范围（只改一个文件）+ 重跑
    → 若引入新失败：回滚第 2 次改动（git checkout），进入第 3 次
  第 3 次重试：仅诊断，不修代码，输出诊断报告
```

**新增约束**：
- 禁止通过修改测试断言来"修复"失败（R18）：在修复前检查 diff 是否只改了测试文件，若是则阻止并提示
- 环境错误不进修复循环（R12）：检测 `ModuleNotFoundError` / `command not found` / `No module named` 等模式，直接报告用户

**诊断报告格式**：
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ 自动修复未能解决，需要人工介入
━━━━━━━━━━━━━━━━━━━━━━━━━━━
失败测试：[测试名]
根因分析：[AI 判断]
已尝试修复：
  - 第 1 轮：[做了什么] → [结果]
  - 第 2 轮：[做了什么] → [结果]（已回滚）
建议手动操作：[具体步骤]
相关文件：[文件列表]
错误日志：[关键行]
━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Patterns to follow:**
- Layer 0 现有 `layer0_inner_retries` 逻辑（扩展为通用模式）

**Test scenarios:**
- Given: TEST_COMMAND 失败; When: 第 1 次修复成功; Then: layers.layer2 = pass，不进入第 2 次
- Given: 第 2 次修复引入新失败; When: 检测到新失败; Then: 回滚第 2 次改动，进入第 3 次仅诊断
- Given: 测试失败原因是 `ModuleNotFoundError: No module named 'foo'`; When: 错误分类; Then: 识别为环境错误，不进修复循环，直接提示用户 `pip install foo`
- Given: AI 试图修改测试文件的断言来修复失败; When: diff 检查; Then: 阻止修改，提示「不应修改测试断言」

**Verification:**
- 修复循环最多执行 3 次内部重试
- 第 3 次只输出诊断报告，不修改代码
- 环境错误跳过修复循环

---

- [ ] **Unit 4: 设计图对比集成**

**Goal:** 有设计文件（.pen/Figma）时，Layer 2 浏览器测试后自动触发设计对比

**Requirements:** R28, R29, R30

**Dependencies:** Unit 2（Layer 2 浏览器路由已实现）

**Files:**
- Modify: `plugins/compound-engineering/skills/ce-work/SKILL.md`（Phase 3.5.2 Layer 2 浏览器测试路由末尾）

**Approach:**

在 Layer 2 浏览器测试（路由 A）完成后，追加设计对比步骤：

```
Layer 2 路由 A 执行完毕后：
  ├─ 检测设计文件：
  │   - Glob: *.pen / *.fig / figma.json
  │   - 或 plan 文档中引用了设计文件路径
  │
  ├─ 若有设计文件：
  │   1. 派发 design-implementation-reviewer agent
  │      → 输入：实现截图 + 设计文件路径
  │      → 输出：差异列表（✅/⚠️/❌）
  │   2. 若有 ❌ Major Issues：
  │      → 派发 design-iterator agent
  │      → 最多 3 轮迭代修复
  │      → 每轮：截图 → 分析 → 修复一处 → 再截图
  │   3. 迭代完成后重新截图对比确认
  │
  └─ 若无设计文件：跳过，不影响 Layer 2 结果
```

**Patterns to follow:**
- `plugins/compound-engineering/agents/design/design-implementation-reviewer.md`（agent 接口）
- `plugins/compound-engineering/agents/design/design-iterator.md`（迭代修复模式）

**Test scenarios:**
- Given: 项目有 .pen 设计文件 + Layer 2 浏览器测试通过; When: 设计对比; Then: 截图 vs 设计稿，输出差异报告
- Given: 设计对比发现 2 个 Major Issues; When: 触发 design-iterator; Then: 最多 3 轮修复，每轮改一处
- Given: 项目无设计文件; When: 设计对比检测; Then: 跳过，不影响 Layer 2 pass/fail

**Verification:**
- 有设计文件时自动触发对比
- 无设计文件时静默跳过
- design-iterator 最多 3 轮

---

- [ ] **Unit 5: Plan 测试场景结构化**

**Goal:** ce:plan 输出的测试场景推荐 Given/When/Then 格式，ce:work 默认 test-first

**Requirements:** R31, R32, R33

**Dependencies:** 无

**Files:**
- Modify: `plugins/compound-engineering/skills/ce-plan/SKILL.md`（Phase 3 Implementation Units 的测试场景格式指导）

**Approach:**

在 ce:plan 的 Phase 3（Structure the Plan）中，测试场景格式指导部分增加：

1. **推荐 Given/When/Then 格式**：
```
**Test scenarios:**
- Given: [前置条件]; When: [操作]; Then: [可验证的断言]
```

2. **Then 断言约束**：必须是可机器验证的谓词：
   - 退出码为 0 / 非 0
   - 输出包含 / 不包含特定字符串
   - 文件存在 / 不存在
   - HTTP 状态码为 200/404/500
   - 模糊断言（「用户体验流畅」）标记为 `(需手动验证)`

3. **默认 test-first 执行姿态**：每个实现单元无显式 Execution note 时，默认 `Execution note: test-first`

**Patterns to follow:**
- 现有 ce:plan 的 Test scenarios 格式（参考当前计划文件中的写法）
- ce:work Phase 2 中「Execution note: test-first」的处理逻辑

**Test scenarios:**
- Given: ce:plan 生成计划; When: 测试场景输出; Then: 格式为 Given/When/Then，Then 为可验证谓词
- Given: 计划中某测试场景 Then 为「用户体验流畅」; When: 格式检查; Then: 标记为 `(需手动验证)`
- Given: 实现单元无 Execution note; When: ce:work 读取; Then: 默认 test-first

**Verification:**
- ce:plan 输出的测试场景使用 Given/When/Then 格式
- 模糊断言被正确标记

---

## System-Wide Impact

- **Phase -1.5 扩展**：新增 TEST_COMMAND 推导（与 START_COMMAND 并列），不改 START_COMMAND 现有逻辑
- **Phase 3.5.1 触发判断**：Layer 2 从二分法变为多路由，新增 TEST_COMMAND / CLI / API 触发信号
- **Phase 3.5.2 Layer 2**：新增非前端分支（TEST_COMMAND / CLI / API），现有浏览器测试分支不变
- **Phase 3.5.2 修复循环**：Layer 0 已有的 `layer0_inner_retries` 模式扩展为所有 Layer 通用
- **ce:plan 测试场景**：格式从散文变为 Given/When/Then（推荐非强制）
- **不变量**：Layer 0（CLI 静态检查）、Layer 1（API/DB 验证）、Layer 3（验收确认）核心逻辑不变

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| TEST_COMMAND 推导不准（monorepo、非标准项目结构） | Level 6 fallback 询问用户，存储后不再问 |
| 测试输出解析不准（非标准框架输出） | 通用 fallback 看退出码 + 原始 stderr |
| 安全检查误拦（用户的 DATABASE_URL 含 amazonaws 但是测试环境） | 警告但不硬阻止，用 AskUserQuestion 让用户确认 |
| Windows 进程清理失败 | 三层防护（PID + trap + 端口扫描）+ 最终宣告 |
| 设计图对比 + 修复迭代耗时过长 | design-iterator 最多 3 轮，超出跳过 |

## Sources & References

- **Origin document:** [docs/brainstorms/2026-04-11-universal-verification-engine-requirements.md](docs/brainstorms/2026-04-11-universal-verification-engine-requirements.md)
- **Phase -1.5 环境指纹:** `plugins/compound-engineering/skills/ce-work/SKILL.md` 第 84-202 行
- **Phase 3.5 四层验证:** `plugins/compound-engineering/skills/ce-work/SKILL.md` 第 570-811 行
- **设计 Agent:** `plugins/compound-engineering/agents/design/design-implementation-reviewer.md`、`design-iterator.md`
