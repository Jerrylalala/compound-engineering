# 规范入口面准确性修复 + CI 防回归

> 需求文档：`docs/brainstorms/2026-04-11-readme-workflow-config-audit-brainstorm.md`
> 一个 PR 完成所有 P0+P1+P2 修复 + CI 防线

## Requirements Trace

- R1: 修正 3 个配置文件的旧仓库 URL（P0 #3）
- R2: 修正中文文档 70+ 处旧命令名 `/workflows:*` → `/ce:*`（P0 #1）
- R3: 移除不存在的 `/workflows:load` 和 `/workflows:save`（P0 #2）
- R4: 修正 README.md agent 数量 57→51（P1 #7）
- R5: 修正 plugin.json command 数量 9→15（P1 #8）
- R6: 修正 workflow.html review 模式描述（P1 #4,#5）
- R7: 修正 workflow.html 派对模式描述（P1 #6）
- R8: 修正安装文档旧仓库名（P2 #9）
- R9: 修正 pencil.html 旧仓库名（P2 #10）
- R10: 修正 workflow.html review 缺 `base:<ref>` + work 缺 badges（P2 #11,#12）
- R11: 扩展 CI 防回归检查（根因修复）

## Implementation Units

### Unit 1: 配置文件 URL 修正 [R1, R5]

修改 3 个文件中的仓库 URL + plugin.json 组件数量。

**文件与变更：**

- [ ] `plugins/compound-engineering/.claude-plugin/plugin.json`
  - `homepage`: `compound-engineering-plugin-private` → `compound-engineering`
  - `repository`: `compound-engineering-plugin-private` → `compound-engineering`
  - `description`: `9 commands` → `15 commands`
- [ ] `.claude-plugin/marketplace.json`
  - `homepage`: `compound-engineering-plugin-private` → `compound-engineering`
- [ ] `package.json`
  - `homepage`: `compound-engineering-plugin-private` → `compound-engineering`
  - `repository`: `compound-engineering-plugin-private` → `compound-engineering`

**验证**：`grep -r "compound-engineering-plugin-private" plugins/compound-engineering/.claude-plugin/ .claude-plugin/ package.json` 应返回 0 结果。

---

### Unit 2: README.md 数量修正 [R4]

- [ ] L173: `ce-review + 57 agents` → `ce-review + 51 agents`
- [ ] L198: `57 agents` → `51 agents`

**验证**：`grep "57 agents" README.md` 应返回 0 结果。

---

### Unit 3: 中文文档命令迁移 [R2, R3, R8]

将所有 `/workflows:*` 替换为 `/ce:*`，移除不存在的命令。

**文件与变更：**

- [ ] `docs/zh-CN/INSTALL.md`
  - 全局替换 `/workflows:brainstorm` → `/ce:brainstorm`（同理 plan, work, review, compound, sync-upstream）
  - 删除 `/workflows:load` 和 `/workflows:save` 行（L72, L79）— 这两个命令不存在
  - 替换旧仓库名 `compound-engineering-plugin-private` → `compound-engineering`（6 处 URL）
  - 删除 L221 的硬编码本地路径 `F:\StudyFolder\...`，改为通用示例
- [ ] `docs/zh-CN/WORKFLOW-VISUAL.md`
  - 全局替换 `/workflows:*` → `/ce:*`（40+ 处）
- [ ] `docs/zh-CN/CONCEPTS.md`
  - 替换 `/workflows:*` → `/ce:*`（5 处）
  - 更新目录结构示例（commands/ 结构已变为 commands/ce/）
- [ ] `docs/zh-CN/CODEX-WORKFLOWS.md`
  - 替换 `/workflows:work` → `/ce:work`（5 处）
- [ ] `README.zh-CN.md`
  - 替换 `/workflows:*` → `/ce:*`（7 处）
  - 替换旧仓库名（3 处 URL）
  - 删除 `/workflows:load` 和 `/workflows:save`（如果存在）
- [ ] `docs/zh-CN/SYNC.md`
  - 替换旧仓库名（1 处 origin URL）
  - 将 `/workflows:sync-upstream` → `/ce:sync-upstream`

**验证**：`grep -r "/workflows:" docs/zh-CN/ README.zh-CN.md --include="*.md" | grep -v "docs/plans\|docs/solutions\|docs/sync-reports"` 应返回 0 结果。

---

### Unit 4: workflow.html 修正 [R6, R7, R10]

修改 JavaScript `steps` 对象和 HTML 特性卡片。

**Review 步骤修正：**

- [ ] 修改 `steps.review.params` 数组：
  - 将 `mode:autofix` 的 label 从"推荐默认"改为"真实实现"，描述改为说明 Interactive 是默认模式
  - 新增 `mode:report-only` 参数卡片（纯只读审查，不修改文件）
  - 新增 `mode:headless` 参数卡片（程序化调用，skill-to-skill）
  - 新增 `base:<ref>` 参数卡片
- [ ] Review 节点 badges：将 `[autofix]` 改为 `[mode:*]` 或类似标注
- [ ] `steps.review.desc`：补充说明默认模式是 Interactive

**Work 步骤修正：**

- [ ] Work 节点 badges（HTML）：添加 `[C]` 和 `[G]` badges

**派对模式卡片修正：**

- [ ] L551：将"14 个专家视角发散讨论"改为区分 `[P]`(3 核心视角) 和 `[P+]`(12-14 视角)
- [ ] 修改"无需额外参数"措辞，改为"收敛自动触发"

**验证**：在浏览器中打开 workflow.html，点击 Review 步骤确认 3 个模式都显示。

---

### Unit 5: pencil.html URL 修正 [R9]

- [ ] `docs/zh-CN/pencil.html`
  - L494, L496, L863, L864：`compound-engineering-plugin-private` → `compound-engineering`（4 处）

**验证**：`grep "plugin-private" docs/zh-CN/pencil.html` 应返回 0 结果。

---

### Unit 6: CI 防回归扩展 [R11]

**6a: 扩展 `scripts/check-feature-integrity.sh`**

新增检查：

- [ ] **组件数量校验**：统计 agents/commands/skills/skills-custom 文件数，与 plugin.json description 中的数字比较
- [ ] **规范 URL 校验**：检查 plugin.json, marketplace.json, package.json 中的 URL 包含 `Jerrylalala/compound-engineering`（不含 `-plugin-private`）
- [ ] **旧命令名校验**：确保 docs/zh-CN/*.md 和 README*.md 中不出现 `/workflows:brainstorm`、`/workflows:plan` 等旧命令名

**6b: 扩展 `.github/workflows/integrity-check.yml` 触发范围**

- [ ] `paths` 新增：
  ```yaml
  - 'README*.md'
  - 'docs/zh-CN/**'
  - '.claude-plugin/**'
  - 'package.json'
  ```

**验证**：运行 `bash scripts/check-feature-integrity.sh`，所有检查通过。

---

### Unit 7: 版本与变更日志 [收尾]

- [ ] `powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -BumpType patch`
- [ ] 更新 `CHANGELOG.md`：在新版本号下记录所有修复
- [ ] `powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1` 验证版本一致
- [ ] 更新 plugin.json description 中的数字为实际值（由 Unit 6 CI 验证）

---

## 执行顺序

```
Unit 1 (配置 URL) ─┐
Unit 2 (README 数量) ─┤
Unit 5 (pencil URL) ─┤── 可并行，无依赖
Unit 3 (中文命令迁移) ─┤
Unit 4 (workflow.html) ─┘
         │
         ▼
Unit 6 (CI 防回归) ── 依赖 Unit 1-5 完成后运行校验
         │
         ▼
Unit 7 (版本+日志) ── 最后执行
```

## 排除清单（不改）

- `docs/plans/**` — 历史计划
- `docs/solutions/**` — 历史经验
- `docs/sync-reports/**` — 历史同步报告
- `CHANGELOG.md` 中描述历史状态的文字
- `plugins/compound-engineering/skills-custom/sync-targets/SKILL.md` — 本地目录名确实是旧名

## 验收标准

1. `grep -r "compound-engineering-plugin-private" plugins/compound-engineering/.claude-plugin/ .claude-plugin/ package.json` = 0 结果
2. `grep -r "/workflows:" docs/zh-CN/ README.zh-CN.md --include="*.md"` = 0 结果（排除 plans/solutions/sync-reports）
3. `grep "57 agents" README.md` = 0 结果
4. `bash scripts/check-feature-integrity.sh` = 全部通过
5. workflow.html Review 面板显示 3 个模式（Interactive/autofix/report-only/headless）
6. workflow.html 派对模式卡片区分 [P](3) 和 [P+](12-14)
