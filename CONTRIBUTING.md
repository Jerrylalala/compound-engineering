# Contributing

Thank you for helping maintain Compound Engineering.

This repository is maintained as a public fork of `EveryInc/compound-engineering-plugin` with Chinese documentation, local workflow improvements, and cross-agent conversion tooling. Public users should be able to install it, understand it, report problems, and contribute without private context.

## Development Setup

Required tools:

- Bun
- Git
- Python 3, only when working on the documentation site

Common commands:

```bash
bun install
bun test
bun run release:validate
```

Documentation checks:

```bash
pip install -r requirements-docs.txt
mkdocs build --strict
```

## Before Opening A Pull Request

Run the checks that match your change:

| Change type | Required checks |
| --- | --- |
| CLI parser, converter, writer, or install behavior | `bun test` |
| Plugin agents, skills, commands, or marketplace metadata | `bun run release:validate` |
| Documentation site or `docs/zh-CN` navigation | `mkdocs build --strict` |
| Feature inventory or user-facing plugin behavior | `bun run release:validate` plus relevant targeted tests |

If a check cannot be run, say exactly why in the pull request and include the freshest local evidence you have.

## Branch And Commit Style

Use focused branches:

- `feat/<short-name>`
- `fix/<short-name>`
- `hotfix/<short-name>`
- `refactor/<short-name>`
- `docs/<short-name>`

Use conventional commit intent with a useful scope:

```text
docs(readme): 更新公共仓库安装说明
fix(cli): 使用当前 fork 作为默认远程源
```

Do not use a broad scope like `compound-engineering` when a narrower scope is clearer.

## Release-Owned Files

Normal feature pull requests should not hand-bump release-owned versions or hand-author release notes.

Release automation owns:

- package versions
- component release notes
- generated release metadata

If plugin inventory or metadata changed, run:

```bash
bun run release:sync-metadata
bun run release:validate
```

## Documentation Standards

Public-facing documentation should answer four questions clearly:

1. What is this project?
2. How do I install and verify it?
3. Which workflow or command should I use?
4. Where do I report bugs, security issues, and contribution questions?

Keep current usage separate from historical notes. In particular, document `ce:*` as the canonical workflow namespace and treat `workflows:*` references as historical or compatibility-only unless a specific runtime still requires them.

## Reporting Issues

Use the GitHub issue templates for bugs and feature requests.

For security vulnerabilities, do not open a public issue. Follow [SECURITY.md](SECURITY.md).

