import { readFile } from "fs/promises"
import path from "path"
import { describe, expect, test } from "bun:test"

async function readRepoFile(relativePath: string): Promise<string> {
  return readFile(path.join(process.cwd(), relativePath), "utf8")
}

describe("ce:work review contract", () => {
  test("requires code review before shipping", async () => {
    const content = await readRepoFile("plugins/compound-engineering/skills/ce-work/SKILL.md")

    // Phase 3 has a mandatory code review step (not optional)
    expect(content).toContain("2. **Code Review**")
    expect(content).not.toContain("Consider Code Review")
    expect(content).not.toContain("Code Review** (Optional)")

    // Two-tier rubric
    expect(content).toContain("**Tier 1: Inline self-review**")
    expect(content).toContain("**Tier 2: Full review (default)**")
    expect(content).toContain("ce:review")
    expect(content).toContain("mode:autofix")

    // Quality checklist includes review
    expect(content).toContain("Code review completed (inline self-review or full `ce:review`)")
  })

  test("delegates commit and PR to dedicated skills", async () => {
    const content = await readRepoFile("plugins/compound-engineering/skills/ce-work/SKILL.md")

    expect(content).toContain("`git-commit-push-pr` skill")
    expect(content).toContain("`git-commit` skill")

    // Should not contain inline PR templates or attribution placeholders
    expect(content).not.toContain("gh pr create")
    expect(content).not.toContain("[HARNESS_URL]")
  })

  test("ce:work-beta mirrors review and commit delegation", async () => {
    const beta = await readRepoFile("plugins/compound-engineering/skills/ce-work-beta/SKILL.md")

    // Both have mandatory review in the extracted shipping workflow
    const shipping = await readRepoFile("plugins/compound-engineering/skills/ce-work-beta/references/shipping-workflow.md")
    expect(shipping).toContain("3. **Code Review**")
    expect(beta).toContain("references/shipping-workflow.md")
    expect(beta).not.toContain("Consider Code Review")

    // Both delegate to git skills
    expect(shipping).toContain("`ce-commit-push-pr` skill")
    expect(shipping).toContain("`ce-commit` skill")
    expect(shipping).not.toContain("gh pr create")
  })

  test("includes per-task testing deliberation in execution loop", async () => {
    const content = await readRepoFile("plugins/compound-engineering/skills/ce-work/SKILL.md")

    // Testing deliberation exists in the execution loop
    expect(content).toContain("Assess testing coverage")

    // Deliberation is between "Run tests after changes" and "Mark task as completed"
    const runTestsIdx = content.indexOf("Run tests after changes")
    const assessIdx = content.indexOf("Assess testing coverage")
    const markDoneIdx = content.indexOf("Mark task as completed")
    expect(runTestsIdx).toBeLessThan(assessIdx)
    expect(assessIdx).toBeLessThan(markDoneIdx)
  })

  test("quality checklist says 'Testing addressed' not 'Tests pass'", async () => {
    const content = await readRepoFile("plugins/compound-engineering/skills/ce-work/SKILL.md")

    // New language present
    expect(content).toContain("Testing addressed")

    // Old language fully removed
    expect(content).not.toContain("Tests pass (run project's test command)")
    expect(content).not.toContain("- All tests pass")
  })

  test("ce:work-beta mirrors testing deliberation and checklist changes", async () => {
    const beta = await readRepoFile("plugins/compound-engineering/skills/ce-work-beta/SKILL.md")

    // Testing deliberation in loop
    expect(beta).toContain("Assess testing coverage")

    const shipping = await readRepoFile("plugins/compound-engineering/skills/ce-work-beta/references/shipping-workflow.md")

    // New checklist language
    expect(shipping).toContain("Testing addressed")

    // Old language removed from the shipping workflow
    expect(shipping).not.toContain("Tests pass (run project's test command)")
    expect(shipping).not.toContain("- All tests pass")
  })
})

describe("ce:brainstorm review contract", () => {
  test("requires document review before handoff", async () => {
    const content = await readRepoFile("plugins/compound-engineering/skills/ce-brainstorm/SKILL.md")

    // Phase 3.5 exists and runs document-review
    expect(content).toContain("### Phase 3.5: Document Review")
    expect(content).toContain("`document-review` skill")

    // Phase 3 and Phase 4 are extracted to references for token optimization
    expect(content).toContain("`references/requirements-capture.md`")
    expect(content).toContain("`references/handoff.md`")

    // Handoff option is for additional passes, not the first review (now in extracted reference)
    const handoff = await readRepoFile("plugins/compound-engineering/skills/ce-brainstorm/references/handoff.md")
    expect(handoff).toContain("**Run additional document review**")
    expect(handoff).not.toContain("**Review and refine**")
  })
})

describe("Codex workflows-brainstorm contract", () => {
  test("keeps Codex brainstorm deep without external AI consultation flags", async () => {
    const content = await readRepoFile(".codex/skills/workflows-brainstorm/SKILL.md")

    expect(content).toContain("[P+]")
    expect(content).toContain("HISTORICAL_RESEARCH")
    expect(content).toContain("自动运行 `$learnings-researcher`")
    expect(content).toContain("最少 2 轮")
    expect(content).toContain("覆盖矩阵")
    expect(content).toContain("完成度门禁")
    expect(content).toContain("不要调用 Codex CLI")
    expect(content).toContain("不要调用 Gemini CLI")

    expect(content).not.toContain("CODEX_ENABLED")
    expect(content).not.toContain("GEMINI_ENABLED")
    expect(content).not.toContain("[C]")
    expect(content).not.toContain("[G]")
  })
})

describe("Codex workflow sync contract", () => {
  test("removes stale ce workflow entrypoints from global Codex sync", async () => {
    const script = await readRepoFile("scripts/sync-codex-workflows.ps1")

    for (const staleEntry of [
      "ce-brainstorm",
      "ce-ideas",
      "ce-ideate",
      "ce-resume",
      "ce-compound-refresh",
      "ce-work",
    ]) {
      expect(script).toContain(`"${staleEntry}"`)
      expect(script).toContain(`"${staleEntry}.md"`)
    }
  })
})

describe("ce:plan testing contract", () => {
  test("flags blank test scenarios on feature-bearing units as incomplete", async () => {
    const content = await readRepoFile("plugins/compound-engineering/skills/ce-plan/SKILL.md")

    // Phase 5.1 review checklist addresses blank test scenarios
    expect(content).toContain("blank or missing test scenarios")
    expect(content).toContain("Test expectation: none")

    // Template comment mentions the annotation convention
    expect(content).toContain("Test expectation: none -- [reason]")
  })
})

describe("ce:plan review contract", () => {
  test("requires document review after confidence check", async () => {
    // Document review instructions extracted to references/plan-handoff.md
    const content = await readRepoFile("plugins/compound-engineering/skills/ce-plan/references/plan-handoff.md")

    // Phase 5.3.8 runs document-review before final checks (5.3.9)
    expect(content).toContain("## 5.3.8 Document Review")
    expect(content).toContain("`document-review` skill")

    // Document review must come before final checks so auto-applied edits are validated
    const docReviewIdx = content.indexOf("5.3.8 Document Review")
    const finalChecksIdx = content.indexOf("5.3.9 Final Checks")
    expect(docReviewIdx).toBeLessThan(finalChecksIdx)
  })

  test("SKILL.md stub points to plan-handoff reference", async () => {
    const content = await readRepoFile("plugins/compound-engineering/skills/ce-plan/SKILL.md")

    // Stub references the handoff file and marks document review as mandatory
    expect(content).toContain("`references/plan-handoff.md`")
    expect(content).toContain("Document review is mandatory")
  })

  test("uses headless mode in pipeline context", async () => {
    const content = await readRepoFile("plugins/compound-engineering/skills/ce-plan/references/plan-handoff.md")

    // Pipeline mode runs document-review headlessly, not skipping it
    expect(content).toContain("document-review` with `mode:headless`")
    expect(content).not.toContain("skip document-review and return control")
  })

  test("handoff options recommend ce:work after review", async () => {
    const content = await readRepoFile("plugins/compound-engineering/skills/ce-plan/references/plan-handoff.md")

    // ce:work is recommended (review already happened)
    expect(content).toContain("**Start `/ce:work`** - Begin implementing this plan in the current environment (recommended)")

    // Document review option is for additional passes
    expect(content).toContain("**Run additional document review**")

    // No conditional ordering based on plan depth (review already ran)
    expect(content).not.toContain("**Options when document-review is recommended:**")
    expect(content).not.toContain("**Options for Standard or Lightweight plans:**")
  })
})
