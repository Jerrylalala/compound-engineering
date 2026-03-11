# 计划审查建议应用摘要

**原计划**：docs/plans/2026-03-11-feat-superpowers-fusion-plan.md

## 应用的修改

### 1. 删除 Task 2（verification-before-completion skill）

**原因**：与 CLAUDE.md 验证铁律有 30% 重叠，增加维护成本。

**替代方案**：将 Agent 委派验证和 TDD 红绿循环验证内容合并到根目录 CLAUDE.md 的验证章节。

**修改位置**：
- 删除：Task 2（行 142-257）
- 新增：Task 2a — 增强根目录 CLAUDE.md 验证章节

### 2. 删除「协作者信号解读」表（Task 13）

**原因**：过于主观，用户说话风格差异大，容易误导 AI。

**修改位置**：
- Task 13 中删除「协作者信号解读」章节
- 保留「无根因分支」章节

### 3. 新增 Task 16.5：集成测试

**内容**：
```markdown
### Task 16.5: 集成测试

**操作**:
- [ ] 重启 Claude Code，确认插件加载无错误
- [ ] 运行 `/skills` 命令，确认 26 个 skills 全部显示（24+2）
- [ ] 在 CLAUDE.md 中搜索新增的 2 个技能，确认映射表正确
- [ ] 运行 `bash scripts/check-handoff.sh` 确认 Handoff 协议未破坏

**验证**:
- [ ] 插件加载无 YAML 解析错误
- [ ] 新 Skill 的 description 正确显示
- [ ] 技能映射表场景描述准确
- [ ] Handoff 协议检查通过
```

### 4. 增强 Task 15：版本号更新

**新增内容**：
```markdown
- [ ] 更新 marketplace.json 中的 skills 数量（24 → 26）
- [ ] 更新 plugin.json 中的 skills 数量（24 → 26）
```

### 5. 增强 Task 10-11：Handoff 验证

**新增验证步骤**：
```markdown
- [ ] 运行 `bash scripts/check-handoff.sh` 确认 Handoff 协议未破坏
- [ ] 确认 finishing-a-feature skill 已存在（Wave 1 完成）
```

### 6. 新增：Rollback Plan

**位置**：计划末尾，References 之前

**内容**：
```markdown
## Rollback Plan

如果某波提交后发现问题：

### Wave 1 回滚
\`\`\`bash
git revert <Wave 1 commit hash>
# 删除 2 个新 Skill 目录
rm -rf plugins/compound-engineering/skills/finishing-a-feature
rm -rf plugins/compound-engineering/skills/receiving-code-review
# 恢复 CLAUDE.md
git checkout HEAD~1 plugins/compound-engineering/CLAUDE.md
\`\`\`

### Wave 2-4 回滚
\`\`\`bash
git revert <commit hash>
\`\`\`

### 完全回滚
\`\`\`bash
git reset --hard <Wave 1 前的 commit>
\`\`\`
```

### 7. 更新任务编号

**原方案**：17 个任务
**新方案**：16 个任务

- Task 1: finishing-a-feature（保留）
- Task 2: receiving-code-review（原 Task 3，重新编号）
- Task 2a: 增强根目录 CLAUDE.md 验证章节（新增，替代原 Task 2）
- Task 3: 更新 plugin CLAUDE.md 映射表（原 Task 4）
- Task 4: Wave 1 提交（原 Task 5）
- Task 5-15: 依次重新编号
- Task 16.5: 集成测试（新增）
- Task 16: 最终提交（原 Task 17）

### 8. 更新 CHANGELOG 内容

**修改**：
```markdown
### Added
- 新增 `finishing-a-feature` skill：功能分支收尾闭环
- 新增 `receiving-code-review` skill：接收审查响应规范
- 增强根目录 CLAUDE.md：补充 Agent 委派验证和 TDD 红绿循环验证模式

### Changed
- （删除 verification-before-completion 相关内容）
```

### 9. 更新组件统计

**修改**：
- Skills: 24 → 26（原计划 27，删除 1 个）
- 所有提到"27 个 skills"的地方改为"26 个 skills"

---

## 执行建议

由于计划文件有 898 行，建议使用以下策略应用修改：

1. **手动编辑关键部分**（高优先级）：
   - 删除 Task 2 全文（行 142-257）
   - 在 Task 2 位置插入新的 Task 2（receiving-code-review）和 Task 2a（CLAUDE.md 增强）
   - 在 Task 13 中删除「协作者信号解读」表
   - 在 Task 15 中补充 marketplace.json/plugin.json 更新
   - 在 Task 10-11 中补充 Handoff 验证
   - 在 Task 16 后插入 Task 16.5（集成测试）
   - 在 References 前插入 Rollback Plan

2. **全局替换**（中优先级）：
   - 将所有"27 个 skills"替换为"26 个 skills"
   - 将所有"3 个 Skill"替换为"2 个 Skill"（仅 Wave 1 标题）

3. **验证修改**（必须）：
   - 运行 `grep -n "Task [0-9]" docs/plans/*.md` 确认任务编号连续
   - 确认所有交叉引用正确

---

**建议**：由于修改较多，可以选择：
- 方案 A：手动逐项应用上述修改
- 方案 B：基于审查建议重新生成简化版计划（DHH 方案 B：150 行而非 1500 行）
