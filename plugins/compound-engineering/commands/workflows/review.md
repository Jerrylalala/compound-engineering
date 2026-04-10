---
name: workflows:review
description: "[C][G][team] 使用多代理进行全面代码审查"
argument-hint: "[PR# 或留空=当前分支] [mode:autofix|report-only|headless] [plan:路径] [base:ref] [C=Codex审核] [G=Gemini审核] [team=合约白名单门控] [team:full]"
---

Invoke skill `compound-engineering:ce-review` with args: $ARGUMENTS
