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

  test("converts commands to GeminiCommand array", () => {
    const bundle = convertClaudeToGemini(fixturePlugin, {
      agentMode: "subagent",
      inferTemperature: false,
      permissions: "none",
    })

    expect(bundle.commands).toHaveLength(1)

    const cmd = bundle.commands[0]
    expect(cmd.name).toBe("workflows:plan")
    expect(cmd.description).toBe("Plan the work.")
    expect(cmd.relativePath).toBe("workflows/plan.toml")
    expect(cmd.prompt).toContain("Plan content.")
    expect(cmd.prompt).toContain("{{args}}")
  })

  test("generates correct paths for namespaced commands", () => {
    const plugin = {
      ...fixturePlugin,
      commands: [
        {
          name: "workflows:review",
          description: "Review code.",
          body: "Review body.",
          sourcePath: "/tmp/plugin/commands/workflows/review.md",
        },
        {
          name: "simple-command",
          description: "Simple command.",
          body: "Simple body.",
          sourcePath: "/tmp/plugin/commands/simple-command.md",
        },
      ],
    }

    const bundle = convertClaudeToGemini(plugin, {
      agentMode: "subagent",
      inferTemperature: false,
      permissions: "none",
    })

    expect(bundle.commands).toHaveLength(2)
    expect(bundle.commands[0].relativePath).toBe("workflows/review.toml")
    expect(bundle.commands[1].relativePath).toBe("simple-command.toml")
  })

  test("handles empty command name after sanitization", () => {
    const plugin = {
      ...fixturePlugin,
      commands: [
        {
          name: "../..",
          description: "Command that becomes empty after sanitization.",
          body: "Body content.",
          sourcePath: "/tmp/plugin/commands/empty.md",
        },
      ],
    }

    const bundle = convertClaudeToGemini(plugin, {
      agentMode: "subagent",
      inferTemperature: false,
      permissions: "none",
    })

    expect(bundle.commands).toHaveLength(1)
    // 空命令名应回退到默认名称
    expect(bundle.commands[0].relativePath).toBe("unnamed-command.toml")
    expect(bundle.commands[0].name).not.toBe("")
  })

  test("sanitizes path traversal attempts in command names", () => {
    const plugin = {
      ...fixturePlugin,
      commands: [
        {
          name: "../etc:passwd",
          description: "Malicious command.",
          body: "Bad body.",
          sourcePath: "/tmp/plugin/commands/bad.md",
        },
        {
          name: "..\\windows:system32",
          description: "Another malicious command.",
          body: "Bad body.",
          sourcePath: "/tmp/plugin/commands/bad2.md",
        },
        {
          name: "normal/slash:test",
          description: "Command with slash in name.",
          body: "Normal body.",
          sourcePath: "/tmp/plugin/commands/normal.md",
        },
      ],
    }

    const bundle = convertClaudeToGemini(plugin, {
      agentMode: "subagent",
      inferTemperature: false,
      permissions: "none",
    })

    // 路径遍历字符 (..) 应被清理
    expect(bundle.commands[0].relativePath).not.toContain("..")
    expect(bundle.commands[1].relativePath).not.toContain("..")
    // 输入中的斜杠应被替换为横杠（命名空间分隔符 : 转换为 / 是正常的）
    expect(bundle.commands[2].relativePath).toBe("normal-slash/test.toml")
    // 验证没有 Windows 反斜杠
    expect(bundle.commands[1].relativePath).not.toContain("\\")
  })

  test("excludes claude-code-only commands from conversion and GEMINI.md", () => {
    const plugin = {
      ...fixturePlugin,
      commands: [
        {
          name: "normal-command",
          description: "Normal command.",
          body: "Normal body.",
          sourcePath: "/tmp/plugin/commands/normal.md",
        },
        {
          name: "gemini",
          description: "Claude-only command.",
          claudeCodeOnly: true,
          body: "Should be excluded.",
          sourcePath: "/tmp/plugin/commands/gemini.md",
        },
        {
          name: "codex",
          description: "Another Claude-only command.",
          claudeCodeOnly: true,
          body: "Should also be excluded.",
          sourcePath: "/tmp/plugin/commands/codex.md",
        },
      ],
    }

    const bundle = convertClaudeToGemini(plugin, {
      agentMode: "subagent",
      inferTemperature: false,
      permissions: "none",
    })

    // 只有 normal-command 应该被转换
    expect(bundle.commands).toHaveLength(1)
    expect(bundle.commands[0].name).toBe("normal-command")

    // GEMINI.md 中也不应列出 claude-code-only 命令
    expect(bundle.geminiMd).toContain("/normal-command")
    expect(bundle.geminiMd).not.toContain("/gemini")
    expect(bundle.geminiMd).not.toContain("/codex")
  })
})
