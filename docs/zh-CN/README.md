# 中文文档（zh-CN）

本目录用于存放中文说明与使用指南。

## 中文镜像策略

**核心原则：我们不修改上游英文文件，中文内容集中在独立目录，以最大限度降低同步上游时的冲突。**

### 文件分布

| 内容类型 | 存放位置 | 说明 |
|---------|---------|------|
| 项目中文说明 | `README.zh-CN.md` | 根目录，独立于上游 README.md |
| 中文文档 | `docs/zh-CN/` | 本目录，所有中文文档输出位置 |
| 中文命令 | `commands/workflows-zh/` | 中文版工作流命令 |
| 自定义技能 | `skills-custom/` | 本地技能，不影响上游 |

### 为什么这样设计？

1. **减少冲突**：上游更新时，我们的中文内容不会被覆盖或产生冲突
2. **易于维护**：中文内容集中管理，便于翻译和更新
3. **可追溯**：清晰区分上游内容和本地内容

### 镜像生成流程（后续）

中文文档可以通过以下方式生成：

1. **手动翻译**：直接在 `docs/zh-CN/` 中创建中文版文档
2. **AI 辅助**：使用 Claude 等 AI 工具基于英文文档生成中文版
3. **自动脚本**：（待实现）自动从英文文档生成中文镜像

**重要提醒**：
- 不要直接修改上游英文文件
- 如需修改上游内容，应提交 PR 到上游仓库
- 本地中文内容的修改不需要同步到上游

---

## 快速上手

### 1. 转换并安装到 Codex

```bash
bun run src/index.ts install ./plugins/compound-engineering --to codex
```

### 2. 使用中文命令

| 命令 | 说明 |
|------|------|
| `/workflows-zh:plan` | 把需求描述整理成可执行的计划 |
| `/workflows-zh:work` | 按计划执行并交付 |
| `/workflows-zh:review` | 多代理代码审查 |
| `/workflows-zh:compound` | 沉淀解决方案与知识 |

---

## 自定义技能（Skills）

### 目录结构

```
plugins/compound-engineering/
├── skills/           # 上游技能（不修改）
├── skills-custom/    # 本地生效的自定义技能
└── skills-inbox/     # 技能投递箱（临时存放）
```

### 添加自定义技能

**方式一：直接添加**

```bash
# 在 skills-custom 中创建技能目录
mkdir plugins/compound-engineering/skills-custom/my-skill
# 创建 SKILL.md
```

**方式二：通过投递箱**

1. 把技能放入 `skills-inbox/<skill-name>/`
2. 运行导入脚本：

```powershell
pwsh scripts/import-skills.ps1
```

脚本会把技能复制到 `skills-custom/`，不删除原始文件。

---

## 同步上游

详见 [REPO-SYNC.md](./REPO-SYNC.md)

一键同步：

```powershell
pwsh scripts/sync-upstream.ps1
```

---

## 目录结构

```
docs/zh-CN/
├── README.md         # 本文件 - 中文文档首页和镜像策略说明
└── REPO-SYNC.md      # 仓库同步指南
```
