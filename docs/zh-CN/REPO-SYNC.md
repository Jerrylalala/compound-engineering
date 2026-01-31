# 仓库同步指南

本仓库是 `EveryInc/compound-engineering-plugin` 的 **私有镜像 + 中文化层**。

## 仓库架构

```
┌─────────────────────────────────────────────────────────────┐
│                     仓库关系图                               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  upstream (只读)                 origin (你的私有仓库)        │
│  ┌──────────────────┐           ┌──────────────────┐        │
│  │ EveryInc/        │  fetch    │ Jerrylalala/     │        │
│  │ compound-        │ ────────> │ compound-        │        │
│  │ engineering-     │           │ engineering-     │        │
│  │ plugin           │           │ plugin-private   │        │
│  └──────────────────┘           └──────────────────┘        │
│         │                              ↑                    │
│         │ merge                        │ push               │
│         └──────────────────────────────┘                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Remotes 配置

```text
upstream -> https://github.com/EveryInc/compound-engineering-plugin.git  (上游，只读)
origin   -> https://github.com/Jerrylalala/compound-engineering-plugin-private.git  (你的私有仓库)
```

## 这仓库的作用

1. **镜像上游**：保持与 EveryInc/compound-engineering-plugin 同步
2. **中文化层**：新增中文命令入口与中文文档，不影响上游英文内容
3. **本地扩展**：通过 `skills-custom/` 添加自定义技能，不影响上游

---

## 一键同步上游（推荐）

```powershell
pwsh scripts/sync-upstream.ps1
```

### 脚本执行流程

```
1. git fetch upstream          # 获取上游最新代码
2. git checkout main           # 切换到主分支
3. git merge upstream/main     # 合并上游更新
4. [检测冲突]                   # 如有冲突，停止并显示
5. git push origin main        # 推送到私有仓库
6. bun install                 # 安装依赖
7. bun run ... install --to codex  # 重新生成 Codex 输出
```

---

## 冲突处理策略

### 原则：优先保证上游英文文件原样

| 冲突类型 | 处理方式 |
|---------|---------|
| 上游英文文件 | **接受上游版本**，不保留本地修改 |
| 中文镜像文件 | 按需重新生成，或手动合并 |
| `skills-custom/` | 应无冲突（上游没有此目录） |
| `docs/zh-CN/` | 应无冲突（上游没有此目录） |

### 为什么这样设计？

因为我们遵循 **"只新增，不修改"** 的原则：

- 所有中文内容都放在 **独立目录**（`docs/zh-CN/`）
- 本地技能放在 **独立目录**（`skills-custom/`）
- **不修改**上游的英文文件

这样，上游更新时：
- 中文内容不会被覆盖
- 本地技能不会被影响
- 冲突概率极低

### 如果发生冲突

脚本会自动停止并显示冲突文件。处理步骤：

```powershell
# 1. 查看冲突文件
git status

# 2. 对于上游英文文件，接受上游版本
git checkout --theirs path/to/upstream/file.md

# 3. 对于中文镜像文件，手动编辑或重新生成
# 编辑冲突文件，保留需要的内容

# 4. 标记冲突已解决
git add path/to/file.md

# 5. 完成合并
git commit -m "Merge upstream/main with conflict resolution"

# 6. 推送到私有仓库
git push origin main
```

---

## 手动同步步骤

如果不想用脚本，可以手动执行：

```powershell
# 1. 获取上游最新
git fetch upstream

# 2. 切到主分支
git checkout main

# 3. 合并上游主分支
git merge upstream/main

# 4. 解决冲突（如有）
#   - 修改冲突文件
#   - git add <file>
#   - git commit

# 5. 推送到私有仓库
git push origin main

# 6. 重新生成 Codex 输出
bun install
bun run src/index.ts install ./plugins/compound-engineering --to codex
```

---

## 常见问题

### Q：如何确认当前是否已与上游对齐？

```powershell
git fetch upstream
git log --oneline --decorate --graph --all -n 20
```

### Q：为什么要保持中文化层独立？

为了让你更容易吸收上游更新，减少合并冲突与维护成本。

### Q：如果我想给上游贡献代码怎么办？

1. Fork 上游仓库到你的 GitHub
2. 在 Fork 中创建分支并修改
3. 提交 PR 到上游仓库
4. PR 合并后，通过同步流程获取你的贡献

### Q：skills-custom 会同步到上游吗？

不会。`skills-custom/` 只存在于你的私有仓库，不会影响上游。

### Q：如何添加新的远程仓库？

```powershell
# 添加上游（如果尚未添加）
git remote add upstream https://github.com/EveryInc/compound-engineering-plugin.git

# 验证远程仓库
git remote -v
```

---

## 同步检查清单

每次同步后，确认以下内容：

- [ ] 上游英文文件未被意外修改
- [ ] 中文文档仍然完整 (`docs/zh-CN/`)
- [ ] 自定义技能仍然存在 (`skills-custom/`)
- [ ] 插件可正常加载（重启 Claude Code）
