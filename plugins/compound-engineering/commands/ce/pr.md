---
name: ce:pr
description: "创建 PR 并询问是否合并到主分支"
argument-hint: "[--draft=草稿PR] [--no-merge=仅创建不合并]"
disable-model-invocation: true
---

/workflows:pr $ARGUMENTS
