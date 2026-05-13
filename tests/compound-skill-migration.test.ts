import { describe, expect, test } from "bun:test"
import path from "path"
import { loadClaudePlugin } from "../src/parsers/claude"

const pluginRoot = path.join(process.cwd(), "plugins", "compound-engineering")

describe("compound-engineering command-to-skill migration", () => {
  test("migrated CE helpers are skills and not legacy commands", async () => {
    const plugin = await loadClaudePlugin(pluginRoot)
    const skillNames = new Set(plugin.skills.map((skill) => skill.name))
    const commandNames = new Set(plugin.commands.map((command) => command.name))

    expect(skillNames.has("ce:doctor")).toBe(true)
    expect(skillNames.has("ce:pr")).toBe(true)
    expect(skillNames.has("ce:sync-upstream")).toBe(true)

    expect(commandNames.has("ce:doctor")).toBe(false)
    expect(commandNames.has("ce:pr")).toBe(false)
    expect(commandNames.has("ce:sync-upstream")).toBe(false)
  })
})
