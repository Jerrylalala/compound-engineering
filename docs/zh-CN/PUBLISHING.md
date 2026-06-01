# npm 发布前置清单

本文档只描述发布 `@jerry-jian/compound-plugin` 前需要确认的事项。当前仓库尚未完成 npm 发布，因此公开安装文档仍使用 `@every-env/compound-plugin` 加 `COMPOUND_PLUGIN_GITHUB_SOURCE`。

## 发布前必须确认

| 检查项 | 要求 |
|--------|------|
| npm 包名 | `npm view @jerry-jian/compound-plugin version` 当前应返回 404；发布后应返回版本号 |
| npm 权限 | 发布账号必须拥有 `@jerry-jian` scope 权限 |
| runtime | CLI 入口是 `#!/usr/bin/env bun`，公开安装说明必须使用 `bunx` / Bun |
| package identity | `package.json` 的 `name`、`license`、`homepage`、`repository`、`bugs` 指向 Jerry 公共仓库 |
| release metadata | `bun run release:validate` 通过 |
| tests | `bun test` 通过 |
| docs | `mkdocs build --strict` 通过 |
| package contents | `npm pack --dry-run` 只包含运行 CLI 必需文件，不包含 `tests/`、`.github/`、历史 `docs/` |
| local package smoke | CI 和本地都要从临时目录安装 `npm pack` 产物后运行 `npx compound-plugin --help` 成功 |
| published install smoke | 发布后从干净目录运行 `bunx @jerry-jian/compound-plugin install compound-engineering --to codex` 成功 |

## 当前 release 流程

本仓库使用 release-please 维护 release PR：

1. 普通 PR 合并到 `main`。
2. `.github/workflows/release-pr.yml` 创建或更新 release PR。
3. 维护者检查 release PR 中的组件版本、tag 和 release notes。
4. 合并 release PR 后，由 release-please 创建对应组件的 GitHub Releases。

普通功能 PR 不应手动打 `v*` 标签，也不应手动改 release-owned 版本。

需要预览组件 bump 时，运行 `.github/workflows/release-preview.yml`，或本地执行：

```bash
bun run release:preview -- --title "feat(cli): example" --file src/index.ts
```

## 本地包 smoke test

发布前不要只看 `npm pack --dry-run`。还要验证 tarball 安装后 CLI bin 能启动：

```powershell
$packDir = Join-Path $env:TEMP 'compound-pack-smoke'
$installDir = Join-Path $env:TEMP 'compound-pack-install-smoke'
New-Item -ItemType Directory -Path $packDir,$installDir -Force | Out-Null
npm pack --pack-destination $packDir
$tgz = Get-ChildItem $packDir -Filter '*.tgz' | Select-Object -First 1
Push-Location $installDir
npm init -y
npm install $tgz.FullName
npx compound-plugin --help
Pop-Location
```

不要把 `bunx <本地 tgz 路径>` 当作发布前验收标准；Windows 路径解析对这种写法不稳定。发布后应验 `bunx @jerry-jian/compound-plugin ...`。

## 发布后文档切换

发布成功并完成安装 smoke test 后，再修改：

- `README.md`
- `README.zh-CN.md`
- `docs/zh-CN/INSTALL.md`
- `docs/zh-CN/SUPPORT-MATRIX.md`

把远程安装命令从：

```bash
COMPOUND_PLUGIN_GITHUB_SOURCE=https://github.com/Jerrylalala/compound-engineering \
  bunx @every-env/compound-plugin install compound-engineering --to codex
```

切换为：

```bash
bunx @jerry-jian/compound-plugin install compound-engineering --to codex
```

## 不要做的事

- 不要在 npm 包发布前把 `@jerry-jian/compound-plugin` 写成默认安装命令。
- 不要手动 bump release-owned 版本。
- 不要把发布失败或未验证的安装方式写进 README。
