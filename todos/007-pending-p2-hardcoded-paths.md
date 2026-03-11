# TODO: 硬编码的本地文件路径泄露

## 元数据

- **ID**: 007
- **优先级**: P2
- **状态**: Pending
- **创建日期**: 2026-03-11
- **分类**: Security / Privacy

## 问题描述

### 位置
- `docs/brainstorms/*.md`
- `docs/plans/*.md`

### 现象
文档中包含硬编码的开发者本地文件系统路径（如 `F:\StudyFolder\...`）。

### 影响
- **安全风险（低）** - 泄露开发者文件系统结构
- **隐私问题** - 暴露个人目录命名习惯
- **可移植性差** - 路径在其他环境无效
- **专业性降低** - 看起来像未清理的草稿

## 根本原因

### 产生原因
1. 开发过程中使用绝对路径进行测试
2. 文档生成时未过滤本地路径
3. 缺少提交前的路径检查机制

### 典型场景
```markdown
# 错误示例
参考文件：F:\StudyFolder\StudyDest\project\tools\compound-engineering-plugin-private\docs\example.md

# 正确示例
参考文件：docs/example.md
```

## 解决方案

### 方案 1：批量替换为相对路径（推荐）

**步骤：**
1. **搜索所有硬编码路径**
   ```bash
   grep -r "F:\\StudyFolder" docs/brainstorms/ docs/plans/
   grep -r "/Users/" docs/brainstorms/ docs/plans/
   grep -r "C:\\Users" docs/brainstorms/ docs/plans/
   ```

2. **替换为相对路径**
   - `F:\StudyFolder\...\compound-engineering-plugin-private\docs\example.md`
   - → `docs/example.md`

3. **验证替换结果**
   - 确保相对路径在仓库根目录下有效
   - 检查是否有遗漏的路径

**优点：**
- 彻底解决问题
- 提升可移植性
- 改善专业性

**缺点：**
- 需要逐个文件检查

### 方案 2：添加 Pre-commit Hook

**创建检查脚本：**
```bash
#!/bin/bash
# scripts/check-hardcoded-paths.sh

FORBIDDEN_PATTERNS=(
  "F:\\\\"
  "C:\\\\"
  "/Users/"
  "/home/[^/]+/"
)

for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
  if git diff --cached --name-only | xargs grep -l "$pattern" 2>/dev/null; then
    echo "错误：检测到硬编码的本地路径"
    echo "请使用相对路径替代"
    exit 1
  fi
done
```

**优点：**
- 预防未来问题
- 自动化检查

**缺点：**
- 不解决现有问题

### 方案 3：使用占位符

对于必须引用本地路径的场景，使用占位符：
```markdown
参考文件：<PROJECT_ROOT>/docs/example.md
```

**优点：**
- 明确表示这是可配置路径
- 保持文档通用性

**缺点：**
- 需要用户手动替换

## 验证标准

- [ ] 所有文档中无 `F:\StudyFolder` 路径
- [ ] 所有文档中无 `C:\Users` 路径
- [ ] 所有文档中无 `/Users/` 路径
- [ ] 所有文档中无 `/home/<username>` 路径
- [ ] 添加 pre-commit hook 防止复发
- [ ] 相对路径在仓库根目录下有效

## 相关文件

### 需要检查的目录
- `docs/brainstorms/`
- `docs/plans/`
- `docs/solutions/`（可能也有）
- `docs/zh-CN/`（可能也有）

### 相关脚本
- `scripts/check-hardcoded-paths.sh`（待创建）
- `.git/hooks/pre-commit`（需更新）

## 执行建议

### 快速修复（30 分钟）
1. 搜索所有硬编码路径
2. 批量替换为相对路径
3. 提交修复

### 长期预防（1 小时）
1. 创建路径检查脚本
2. 集成到 pre-commit hook
3. 更新贡献指南

## 安全评估

### 风险等级：低
- **信息泄露**：仅暴露目录结构，无敏感数据
- **攻击面**：无直接安全漏洞
- **隐私影响**：轻微（暴露个人目录命名）

### 建议优先级
虽然安全风险低，但建议尽快修复，因为：
1. 修复成本低（< 1 小时）
2. 提升项目专业性
3. 改善可移植性

## 备注

这是一个常见的开发疏忽，建议：
1. 立即修复现有问题
2. 添加自动化检查防止复发
3. 在贡献指南中明确说明路径规范
