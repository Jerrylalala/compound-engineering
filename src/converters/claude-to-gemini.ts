import type { ClaudeCommand, ClaudePlugin } from "../types/claude"
import type { GeminiBundle } from "../types/gemini"
import type { ClaudeToOpenCodeOptions } from "./claude-to-opencode"

export type ClaudeToGeminiOptions = ClaudeToOpenCodeOptions

export function convertClaudeToGemini(
  plugin: ClaudePlugin,
  _options: ClaudeToGeminiOptions,
): GeminiBundle {
  return {
    geminiMd: renderGeminiMarkdown(plugin),
  }
}

function renderGeminiMarkdown(plugin: ClaudePlugin): string {
  const sections: string[] = []
  sections.push(...renderSystemContext(plugin))
  sections.push("")
  sections.push(...renderConventions(plugin))
  sections.push("")
  sections.push(...renderCommands(plugin.commands))

  return sections.join("\n").trimEnd() + "\n"
}

function renderSystemContext(plugin: ClaudePlugin): string[] {
  const lines: string[] = []
  lines.push("# System Context")
  lines.push("")
  lines.push(`- Project: ${plugin.manifest.name}`)
  if (plugin.manifest.description) {
    lines.push(`- Description: ${plugin.manifest.description}`)
  } else {
    lines.push("- Description: (not provided in plugin manifest)")
  }
  if (plugin.manifest.version) {
    lines.push(`- Version: ${plugin.manifest.version}`)
  }
  return lines
}

function renderConventions(plugin: ClaudePlugin): string[] {
  const lines: string[] = []
  lines.push("# Conventions")
  lines.push("")
  if (plugin.claudeMd && plugin.claudeMd.trim().length > 0) {
    lines.push("Source: CLAUDE.md")
    lines.push("")
    lines.push(demoteHeadings(plugin.claudeMd.trim()))
  } else {
    lines.push("No CLAUDE.md found in the plugin root. Add one to define conventions.")
  }
  return lines
}

function renderCommands(commands: ClaudeCommand[]): string[] {
  const lines: string[] = []
  lines.push("# Commands/Tools")
  lines.push("")
  if (commands.length === 0) {
    lines.push("No commands defined in this plugin.")
    return lines
  }

  for (const command of commands) {
    lines.push(renderCommandLine(command))
  }

  return lines
}

function renderCommandLine(command: ClaudeCommand): string {
  const commandName = command.name.startsWith("/") ? command.name : `/${command.name}`
  const details: string[] = []

  if (command.description) details.push(command.description)
  if (command.argumentHint) details.push(`Arguments: ${command.argumentHint}`)
  if (command.allowedTools && command.allowedTools.length > 0) {
    details.push(`Allowed tools: ${command.allowedTools.join(", ")}`)
  }

  if (details.length === 0) {
    details.push("No description or metadata provided.")
  }

  return `- To run \`${commandName}\`: ${details.join(" ")}`
}

function demoteHeadings(markdown: string): string {
  return markdown
    .split("\n")
    .map((line) => line.replace(/^(#{1,5})(\s+)/, (_match, hashes: string, space: string) => `#${hashes}${space}`))
    .join("\n")
}
