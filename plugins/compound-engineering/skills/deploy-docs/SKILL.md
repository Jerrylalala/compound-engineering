---
name: deploy-docs
description: Validate the MkDocs documentation site and GitHub Pages deployment for the public repository
disable-model-invocation: true
---

# Deploy Documentation Command

Validate the public documentation site and GitHub Pages deployment for
`Jerrylalala/compound-engineering`.

## Step 1: Validate Documentation

Run these checks:

```bash
bun run release:validate
python -m mkdocs build --strict
```

If Python dependencies are missing, install them first:

```bash
pip install -r requirements-docs.txt
```

## Step 2: Check GitHub Pages Workflow

```bash
test -f .github/workflows/docs.yml
gh workflow view docs.yml --repo Jerrylalala/compound-engineering
```

The workflow should:

- Build with `mkdocs build --strict`.
- Upload the generated `site/` directory.
- Deploy to GitHub Pages with `actions/deploy-pages`.

## Step 3: Check for Uncommitted Changes

```bash
git status --porcelain
```

If `mkdocs build` created an untracked `site/` directory, remove it before
committing unless the user explicitly asked to inspect the built artifact.

## Step 4: Deployment Instructions

After merging to `main`, docs deploy automatically when files matched by
`.github/workflows/docs.yml` change. Manual deployment is also available:

1. Open the repository Actions tab.
2. Select `部署文档站点`.
3. Click `Run workflow`.

## Step 5: Verify Published Pages

Check the deployed public URLs:

```bash
for url in \
  https://jerrylalala.github.io/compound-engineering/ \
  https://jerrylalala.github.io/compound-engineering/INSTALL/ \
  https://jerrylalala.github.io/compound-engineering/SUPPORT-MATRIX/ \
  https://jerrylalala.github.io/compound-engineering/PUBLISHING/ \
  https://jerrylalala.github.io/compound-engineering/workflow.html \
  https://jerrylalala.github.io/compound-engineering/pencil.html
do
  curl -fsSL -o /dev/null "$url" && echo "ok $url"
done
```

## Step 6: Report Status

Provide a summary:

```
## Deployment Readiness

✓ release metadata valid
✓ MkDocs strict build passed
✓ docs workflow exists
✓ published pages return HTTP 200

### Next Steps
- [ ] Commit any pending changes
- [ ] Push to main branch
- [ ] Verify the `部署文档站点` workflow passed
- [ ] Check deployment at https://jerrylalala.github.io/compound-engineering/
```
