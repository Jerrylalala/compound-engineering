# 上游同步工作流

> **用途**：当用户说"同步上游"或"更新插件"时，按此流程操作。

## 前置条件

- 当前目录：`compound-engineering-plugin-private`
- 已配置 remote：
  - `origin` → 用户私人仓库 `Jerrylalala/compound-engineering-plugin-private`
  - `upstream` → 上游仓库 `EveryInc/compound-engineering-plugin`

---

## 第一步：检测上游更新

```bash
# 1. 获取上游最新状态
git fetch upstream

# 2. 查看本地与上游的差异
git log --oneline HEAD..upstream/main

# 3. 如果有输出，说明上游有新提交
```

### 输出示例

**有更新时**：
```
abc1234 feat: add new agent
def5678 fix: command typo
```

**无更新时**：
```
(无输出)
```

### 与用户交互

- 如果**无更新**：告知用户"上游没有新更新"，流程结束
- 如果**有更新**：显示更新列表，询问用户是否继续同步

---

## 第二步：同步上游到本地

```bash
# 1. 确保在 main 分支
git checkout main

# 2. 合并上游
git merge upstream/main
```

### 处理合并冲突

如果出现冲突：

1. **列出冲突文件**：
   ```bash
   git status
   ```

2. **分析每个冲突文件**，按以下原则处理：

   | 文件类型 | 处理方式 |
   |---------|---------|
   | 上游英文文件 | 接受上游版本 (`git checkout --theirs`) |
   | `docs/zh-CN/*` | 保留本地版本 (`git checkout --ours`) |
   | `skills-custom/*` | 保留本地版本 |
   | `CLAUDE.md` | 手动合并，保留两边内容 |
   | 其他 | 与用户讨论 |

3. **解决冲突后**：
   ```bash
   git add .
   git commit -m "Merge upstream/main - 同步上游更新"
   ```

### 与用户交互

- 显示合并结果摘要
- 如有复杂冲突，展示冲突内容并询问用户如何处理
- 确认合并完成

---

## 第三步：推送到私人仓库

```bash
# 推送到 origin (用户的私人 GitHub 仓库)
git push origin main
```

### 可能的问题

- **认证失败**：提醒用户检查 GitHub 凭据
- **push 被拒绝**：可能是远程有本地没有的提交，需要先 pull

### 与用户交互

- 确认推送成功
- 显示 GitHub 仓库链接：`https://github.com/Jerrylalala/compound-engineering-plugin-private`

---

## 第四步：重新加载插件

由于使用 `--plugin-dir` 方式加载插件，**只需重启 Claude Code** 即可加载最新内容。

### 告知用户

```
同步完成！请执行以下操作加载最新插件：

1. 关闭当前 Claude Code
2. 运行启动脚本：
   - Windows: 双击 start-claude.bat
   - macOS:   ./start-claude.sh
3. 输入 /help 验证插件已加载
```

---

## 第五步：更新组件统计（如有变化）

如果上游更新了 agents、commands 或 skills，需要更新文档中的统计数字：

```bash
# 统计组件数量
find plugins/compound-engineering/agents -name "*.md" | wc -l
find plugins/compound-engineering/commands -name "*.md" | wc -l
ls -d plugins/compound-engineering/skills/*/ | wc -l
```

需要同步更新的地方：
- `CLAUDE.md` → 当前组件统计表格
- `.claude-plugin/marketplace.json` → description
- `plugins/compound-engineering/.claude-plugin/plugin.json` → description

---

## 完整流程图

```
用户触发同步
     ↓
[检测上游] ─── 无更新 ──→ 结束
     │
   有更新
     ↓
[显示更新列表] → 用户确认
     ↓
[合并上游] ─── 有冲突 ──→ [解决冲突] → 用户确认
     │
   无冲突
     ↓
[推送到 origin]
     ↓
[提示重启 Claude Code]
     ↓
[更新组件统计（如需）]
     ↓
   完成
```

---

## 快捷命令

用户可以说以下话来触发此工作流：

- "同步上游"
- "更新插件"
- "拉取最新代码"
- "sync upstream"

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `scripts/sync-upstream.ps1` | 自动化同步脚本（可选） |
| `docs/zh-CN/REPO-SYNC.md` | 详细同步策略说明 |
| `docs/zh-CN/INSTALL.md` | 插件安装指南 |
