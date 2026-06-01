# 版本与发布规范

> 本仓库使用 release-please 管理公开版本、release PR、GitHub Releases 和发布元数据。常规功能 PR 不手动 bump 版本，也不手写 release notes。

## 权威来源

| 内容 | 权威来源 | 说明 |
|------|----------|------|
| 组件当前版本 | `.github/.release-please-manifest.json` + 各组件 manifest | release-please 在 release PR 中同步 |
| 公开 release notes | GitHub release PR / GitHub Releases | 根目录 `CHANGELOG.md` 只是指向发布历史的入口 |
| 插件展示元数据 | `plugins/*/.claude-plugin/plugin.json`、`plugins/*/.cursor-plugin/plugin.json`、marketplace manifest | 由 `bun run release:sync-metadata` / `bun run release:validate` 校验 |
| `compound-engineering` 组件数量 | 实际文件树 | `release:validate` 会核对 agents / commands / skills / MCP server 数量 |

## 常规 PR 规则

- 使用 conventional commit 标题，让 release-please 判断 bump 类型，例如 `feat(cli): ...`、`fix(ce-update): ...`、`docs(install): ...`。
- 不直接修改 release-owned 版本字段，除非你正在处理 release PR 或修复 release automation。
- 不在普通 PR 中手写 `CHANGELOG.md` 或插件 changelog 条目。
- 修改插件 manifest、marketplace、组件数量、安装说明或转换输出后，运行 `bun run release:validate`。
- 需要预览 bump 分类时运行 `bun run release:preview -- --title "<commit title>" --file <path>`。

## Release PR 流程

1. 普通 PR 合并到 `main`。
2. `.github/workflows/release-pr.yml` 创建或更新 release PR。
3. 维护者检查 release PR 中的组件版本、tag 名称和 release notes。
4. 合并 release PR 后，release-please 创建对应 GitHub Releases。
5. 如涉及 npm 发布，再按 `docs/zh-CN/PUBLISHING.md` 做包内容和安装 smoke test。

## 验证命令

```bash
bun run release:validate
bun run release:preview -- --title "feat(cli): example" --file src/index.ts
bash scripts/check-feature-integrity.sh
```

`scripts/check-versions.ps1` 和 `scripts/check-versions.sh` 是轻量身份/版本格式检查，可作为本地辅助检查；公开发布前仍以 `bun run release:validate` 为准。

## 旧版手工工具

`scripts/bump-version.ps1` 只保留给历史流程维护或 release automation 故障排查。常规开发不要使用它来准备发版。

如果确实需要运行该脚本，必须在 PR 中说明原因，并随后运行：

```bash
bun run release:sync-metadata
bun run release:validate
```

## 组件数量或描述变更

新增、删除或移动 agents / commands / skills / MCP server 后：

- 更新用户可见说明，例如 `README.md`、`plugins/compound-engineering/README.md`、`docs/zh-CN/SUPPORT-MATRIX.md`。
- 运行 `bun run release:sync-metadata` 同步描述字段。
- 运行 `bun run release:validate` 确认没有 release metadata drift。
- 如修改 `ce-*` skill 参数或功能描述，运行 `bash scripts/check-feature-integrity.sh`。

## 常见问题

### release metadata drift

先运行：

```bash
bun run release:sync-metadata
bun run release:validate
```

如果仍失败，检查 `.github/release-please-config.json`、`.github/.release-please-manifest.json` 和对应插件 manifest 是否表达了同一个组件版本。

### Marketplace 显示旧版本

先确认 release PR 已合并并生成 GitHub Release，再清理本地 marketplace 缓存或重新添加 marketplace。不要通过手工改 marketplace 版本字段绕过 release-please。

### linked versions 看起来多 bump 了 CLI

`cli` 和 `compound-engineering` 使用 release-please 的 linked versions 策略保持同步。只有插件变更也可能带动 CLI 版本，这属于当前设计，不是 metadata drift。

## 相关文档

- [脚本使用说明](../zh-CN/SCRIPTS.md)
- [版本管理预防策略](../zh-CN/VERSION-STRATEGY.md)
- [npm 发布前置清单](../zh-CN/PUBLISHING.md)
