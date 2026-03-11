# TODO: Plan Header 模板缺少示例

## 元数据

- **ID**: 005
- **优先级**: P2
- **状态**: Pending
- **创建日期**: 2026-03-11
- **分类**: Documentation / Usability

## 问题描述

### 位置
- 文件：`plugins/compound-engineering/commands/workflows/plan.md`
- 行号：236-244

### 现象
Plan Header 模板只有结构定义，缺少具体示例。

### 影响
- 降低可理解性
- 新用户难以快速上手
- 可能导致格式使用错误

## 根本原因

文档编写时只提供了抽象的结构说明，未添加实际使用示例。

## 解决方案

### 方案 1：添加完整示例（推荐）

**步骤：**
1. 阅读 `plugins/compound-engineering/commands/workflows/plan.md` 第 236-244 行
2. 基于现有结构创建 2-3 个真实场景的示例：
   - 简单功能开发计划
   - 复杂重构计划
   - Bug 修复计划
3. 每个示例包含完整的 Header 内容
4. 添加注释说明各字段的填写要点

**优点：**
- 大幅提升可理解性
- 降低学习成本
- 减少格式错误

**缺点：**
- 增加文档长度（约 50-100 行）

### 方案 2：引用外部示例

如果项目中已有完整的 Plan 示例文件，可以添加引用链接。

## 验证标准

- [ ] 至少包含 2 个完整的 Plan Header 示例
- [ ] 示例覆盖不同复杂度的场景
- [ ] 每个字段都有实际内容（非占位符）
- [ ] 添加必要的注释说明

## 相关文件

- `plugins/compound-engineering/commands/workflows/plan.md`
- `docs/plans/*.md`（可能包含现有示例）

## 备注

此问题属于文档质量改进，不影响功能。建议在下次文档维护周期中添加示例。
