# Fork 仓库初始化清单

> 从 `EveryInc/compound-engineering-plugin` fork 后，必须完成以下初始化步骤。

## 为什么需要初始化？

Fork 仓库默认继承上游的身份信息（作者、仓库地址等）。如果不修改：
- Claude Code 无法正确识别你的 fork 仓库
- Marketplace 安装时会指向错误的仓库
- 贡献者信息不正确

---

## 初始化清单

### 步骤 1: 修改身份信息

修改以下 2 个文件中的身份信息：

#### 1.1 `.claude-plugin/marketplace.json`

```json
{
  "name": "your-marketplace",  // 修改为你的 marketplace 名称
  "owner": {
    "name": "Your Name",       // 修改为你的名字
    "url": "https://github.com/YourUsername"  // 修改为你的 GitHub
  },
  "plugins": [
    {
      "author": {
        "name": "Your Name (fork of Kieran Klaassen)",  // 保留原作者署名
        "url": "https://github.com/YourUsername"
      },
      "homepage": "https://github.com/YourUsername/your-repo-name"
    }
  ]
}
```

#### 1.2 `plugins/compound-engineering/.claude-plugin/plugin.json`

```json
{
  "author": {
    "name": "Your Name (fork of Kieran Klaassen)",
    "url": "https://github.com/YourUsername"
  },
  "homepage": "https://github.com/YourUsername/your-repo-name",
  "repository": "https://github.com/YourUsername/your-repo-name"
}
```

### 步骤 2: 更新安装说明

修改 `CLAUDE.md` 中的安装命令：

```markdown
/plugins → Add marketplace → YourUsername/your-repo-name
```

### 步骤 3: 配置上游 remote（可选但推荐）

```bash
# 添加上游仓库以便同步更新
git remote add upstream https://github.com/EveryInc/compound-engineering-plugin.git
git remote -v  # 验证配置
```

### 步骤 4: 运行验证脚本

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1

# macOS/Linux
bash scripts/check-versions.sh
```

### 步骤 5: 提交初始化变更

```bash
git add .
git commit -m "Initialize fork: update identity information

- Update marketplace.json with new owner
- Update plugin.json with new author and URLs
- Configure for public fork use"
git push origin main
```

---

## 验证清单

完成初始化后，确认以下内容：

| 检查项 | 预期值 |
|--------|--------|
| `marketplace.json` owner.url | 你的 GitHub URL |
| `plugin.json` homepage | 你的仓库 URL |
| `plugin.json` repository | 你的仓库 URL |
| `CLAUDE.md` 安装命令 | 你的仓库路径 |
| release metadata | `bun run release:validate` 通过 |

---

## 常见错误

### 错误 1: Claude Code 无法识别仓库

**症状**: 安装插件时找不到或指向错误仓库

**原因**: `homepage` 或 `repository` 仍指向上游

**解决**: 按步骤 1.2 修改 plugin.json

### 错误 2: Marketplace 更新失败

**症状**: 执行 `/plugins` 更新时提示已是最新，但实际有更新

**原因**: release metadata 未同步或 marketplace 缓存未刷新

**解决**: 运行 `bun run release:sync-metadata` 和 `bun run release:validate`，再刷新 marketplace 缓存

### 错误 3: 上游同步冲突

**症状**: `git merge upstream/main` 时身份信息冲突

**原因**: 上游更新了相同文件

**解决**: 保留你的身份信息，合并其他更改

---

## 相关文档

- [上游同步指南](./SYNC.md) - 如何从上游获取更新
- [安装与使用](./INSTALL.md) - 完整安装指南
