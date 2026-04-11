---
date: 2026-04-11
topic: universal-verification-engine
---

# 通用自动化验证引擎：扩展 [V] Layer 2

## Problem Frame

当前 `[V]` 模式的 Layer 2 仅支持「启动 Web 应用 + Playwright 浏览器测试」。非前端项目（API、CLI、Python、Rust）跑完 `ce:work [V]` 后，Layer 2 无事可做，用户仍需手动跑测试验证。

独立开发者的期望：做完功能后，**不管项目类型**，一条命令跑完所有验证，失败自动修复，修不了给诊断报告。

## Requirements

### TEST_COMMAND 检测与持久化

- R1. 新增 TEST_COMMAND 推导逻辑（与 START_COMMAND 并列），优先级表 8 级：CLAUDE.md 用户覆盖 → package.json scripts.test → Makefile/Justfile test target → pytest 配置 → Cargo.toml → go.mod → 文件名推断 → 询问用户
- R2. TEST_COMMAND 持久化到 CLAUDE.md 注释（`<!-- ce-work-test-command: X -->`），跨会话复用
- R3. 漂移检测：若本次会话修改了 package.json / Cargo.toml / pyproject.toml，重新推导 TEST_COMMAND 并与存储值比对
- R4. 包管理器前缀检测复用 START_COMMAND 已有的 PKG_RUN 逻辑（pnpm/yarn/npm）
- R5. Monorepo 处理：根 package.json 有 scripts.test 则用根命令；否则根据变更文件范围定位子包
- R6. npm 默认空 test 命令排除：`"echo \"Error: no test specified\" && exit 1"` 不视为有效 TEST_COMMAND

### Layer 2 通用验证路由

- R7. Layer 2 根据项目类型选择验证策略：有 START_COMMAND + UI 项目 → 浏览器测试（已有）；非前端项目 → 跑 TEST_COMMAND
- R8. CLI 项目附加验证：跑 `--help` 验证可执行 + plan 中指定的典型输入验证退出码和 stdout
- R9. API 项目附加验证（可选）：若 plan 中有 API endpoint 验收条件，启动服务后用 curl 验证响应状态码和结构

### 测试输出解析

- R10. 解析测试输出内容，不仅依赖退出码：提取通过数/失败数/跳过数
- R11. 检测「空跑」模式（0 tests ran / no tests collected），标记为警告而非通过
- R12. 区分环境错误（ModuleNotFoundError / command not found）与代码错误，环境错误不进入修复循环

### 自动修复循环

- R13. 测试失败后进入自动修复循环，最多 3 轮
- R14. 第 1 轮：完整诊断 + 修复 + 重跑
- R15. 第 2 轮：缩小范围，只改一个文件 + 重跑
- R16. 第 3 轮：不修代码，只输出诊断报告（根因、文件、建议操作、错误日志）
- R17. 第 2 轮若引入新失败，回滚第 2 轮改动后进入第 3 轮诊断
- R18. 禁止通过修改测试断言来"修复"失败（除非测试本身有明确 bug）

### 安全约束

- R19. 启动服务必须绑定 127.0.0.1，不允许 0.0.0.0
- R20. 启动前扫描 .env 中的 DATABASE_URL / API key，检测是否指向生产环境，疑似生产则警告并阻止
- R21. 禁止在测试阶段执行 migration 命令（db:migrate / alembic upgrade / diesel migration）
- R22. 所有进程设 300 秒硬超时，超时 SIGKILL

### 进程管理与清理

- R23. PID 追踪：启动的每个进程记录 PID 到临时文件
- R24. trap EXIT 兜底：无论正常/异常退出都触发清理
- R25. 端口扫描兜底：清理后检查目标端口是否仍被占用，残留则宣告
- R26. 临时文件统一写入 `$TMPDIR/ce-verify-$SESSION_ID/`，成功删除，失败保留日志
- R27. 跨平台适配：Windows Git Bash 环境用 taskkill/netstat 替代 kill/lsof

### 设计图对比集成（有设计图时）

- R28. 若项目有 .pen 或 Figma 设计文件，Layer 2 触发 design-implementation-reviewer 截图对比
- R29. 发现视觉差异时，调用 design-iterator 自动修复迭代
- R30. 设计图对比与浏览器功能测试串行执行：先功能测试（点击/交互），再视觉对比

### Plan 测试场景结构化

- R31. ce:plan 的测试场景推荐使用 Given/When/Then 格式，AI 可直接转为可执行测试
- R32. Then 断言必须是可机器验证的谓词（状态码、输出包含字符串、文件存在、退出码），模糊断言标记为「需手动验证」
- R33. ce:work 默认 test-first 执行姿态：每个实现单元先写失败测试再实现

## Success Criteria

- 用户跑 `/ce:work [V]`，非前端项目（Python/Rust/CLI/API）也能自动跑 TEST_COMMAND 并反馈结果
- TEST_COMMAND 检测准确率 ≥ 90%（常见项目结构），不准时最多问用户一次
- 测试失败后 3 轮修复循环内解决率 ≥ 60%
- 进程清理成功率 ≥ 99%（测试后无残留进程/端口占用）
- 有设计图的 UI 项目，实现与设计视觉一致性由 AI 自动验证

## Scope Boundaries

- **不做**：自动安装依赖工具（pytest/cargo 等），只提示用户安装命令
- **不做**：自动创建/删除测试数据库，只检查是否指向测试环境
- **不做**：自动发现并测试所有 API 端点（只测 plan 中明确的验收条件）
- **不做**：跨平台 shell 兼容层（TEST_COMMAND 就是一条命令，用户保证可执行性）
- **不做**：模糊断言的自动验证（「用户体验流畅」等标记为需手动验证）
- **不做**：跨浏览器并行测试（只跑一个浏览器实例）

## Key Decisions

- **复用环境指纹而非新建检测机制**：TEST_COMMAND 与 START_COMMAND 共用推导框架和持久化格式，减少新代码量（see Party Mode 代码专家视角）
- **自动修复最多 3 轮而非无限循环**：测试专家和 Codex 一致认为超过 3 轮只会越修越错
- **不造跨语言统一测试框架**：每种项目类型用原生工具（pytest/cargo test/jest），只做编排（see 魔鬼代言人质疑）
- **设计图对比是可选增强**：有设计文件时自动触发，没有则跳过（see 极简主义者观点）
- **Plan Given/When/Then 是推荐而非强制**：散文描述仍然可用，只是 AI 无法自动转为可执行测试

## Dependencies / Assumptions

- 环境指纹（Phase -1.5）已存在且稳定
- Playwright MCP 已配置（[V+] 模式的前提）
- design-implementation-reviewer / design-iterator agent 已存在
- 用户机器上的测试工具（pytest/cargo/jest）已安装

## Outstanding Questions

### Resolve Before Planning

- TEST_COMMAND 推导与 START_COMMAND 推导如何共存于 Phase -1.5？是同一阶段并行推导，还是顺序执行？

### Can Resolve During Planning

- 自动修复循环中，如何精确判断「测试本身有 bug」vs「实现有 bug」？
- API endpoint 验证的 curl 请求模板如何生成？是从 plan 提取还是从路由文件扫描？
