import { describe, expect, test } from "bun:test"
import { convertClaudeToGemini } from "../src/converters/claude-to-gemini"
import type { ClaudePlugin } from "../src/types/claude"

const fixturePlugin: ClaudePlugin = {
  root: "/tmp/plugin",
  manifest: {
    name: "fixture-plugin",
    version: "1.0.0",
    description: "Fixture plugin for Gemini conversion.",
  },
  agents: [],
  commands: [
    {
      name: "workflows:plan",
      description: "Plan the work.",
      argumentHint: "[FOCUS]",
      allowedTools: ["Read", "Write"],
      body: "Plan content.",
      sourcePath: "/tmp/plugin/commands/workflows/plan.md",
    },
  ],
  skills: [],
  hooks: undefined,
  mcpServers: undefined,
  claudeMd: "# Sample Plugin Guide\n\n## Conventions\n\n- Use snake_case.\n",
}

describe("convertClaudeToGemini", () => {
  test("renders system context, conventions, and commands", () => {
    const bundle = convertClaudeToGemini(fixturePlugin, {
      agentMode: "subagent",
      inferTemperature: false,
      permissions: "none",
    })

    const content = bundle.geminiMd
    expect(content).toContain("# System Context")
    expect(content).toContain("- Project: fixture-plugin")
    expect(content).toContain("- Description: Fixture plugin for Gemini conversion.")

    expect(content).toContain("# Conventions")
    expect(content).toContain("## Sample Plugin Guide")
    expect(content).toContain("### Conventions")

    expect(content).toContain("# Commands/Tools")
    expect(content).toContain("To run `/workflows:plan`")
    expect(content).toContain("Plan the work.")
    expect(content).toContain("Arguments: [FOCUS]")
    expect(content).toContain("Allowed tools: Read, Write")
  })

  test("handles missing CLAUDE.md content", () => {
    const bundle = convertClaudeToGemini(
      {
        ...fixturePlugin,
        claudeMd: undefined,
      },
      {
        agentMode: "subagent",
        inferTemperature: false,
        permissions: "none",
      },
    )

    expect(bundle.geminiMd).toContain("No CLAUDE.md found in the plugin root")
  })
})
