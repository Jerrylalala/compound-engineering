import type { ClaudeCommand, ClaudePlugin } from "../types/claude"
import type { GeminiBundle, GeminiCommand } from "../types/gemini"
import type { ClaudeToOpenCodeOptions } from "./claude-to-opencode"

export type ClaudeToGeminiOptions = ClaudeToOpenCodeOptions

/**
 * 将 Claude 插件转换为 Gemini CLI 格式
 *
 * 注意：Gemini CLI 当前仅支持以下功能：
 * - ✅ commands → TOML 命令文件
 * - ✅ claudeMd → GEMINI.md 系统上下文
 *
 * 以下功能不被 Gemini CLI 支持，将被忽略：
 * - ❌ agents（Gemini CLI 无 agent 概念）
 * - ❌ skills（Gemini CLI 无 skill 概念）
 * - ❌ hooks（Gemini CLI 无 hook 支持）
 * - ❌ mcpServers（Gemini CLI 无 MCP 支持）
 *
 * @param plugin Claude 插件对象
 * @param _options 选项（保留用于未来扩展）
 */
export function convertClaudeToGemini(
  plugin: ClaudePlugin,
  _options: ClaudeToGeminiOptions,
): GeminiBundle {
  return {
    geminiMd: renderGeminiMarkdown(plugin),
    commands: convertCommands(plugin.commands),
  }
}

/**
 * 将 Claude 命令转换为 Gemini TOML 命令格式
 */
function convertCommands(commands: ClaudeCommand[]): GeminiCommand[] {
  return commands.map((cmd) => {
    const name = cmd.name.startsWith("/") ? cmd.name.slice(1) : cmd.name
    const relativePath = buildCommandPath(name)
    const description = cmd.description || `Run ${name} command`
    const prompt = buildCommandPrompt(cmd)

    return {
      name,
      description,
      prompt,
      relativePath,
    }
  })
}

/**
 * 根据命令名生成相对路径
 * 例如: "workflows:plan" -> "workflows/plan.toml"
 */
function buildCommandPath(name: string): string {
  // 清理命令名：移除路径遍历字符和危险字符
  const sanitized = sanitizeCommandName(name)
  // P2 修复：空结果回退到默认名称
  const sanitizedName = sanitized || "unnamed-command"
  const parts = sanitizedName.split(":")
  if (parts.length === 1) {
    return `${sanitizedName}.toml`
  }
  // workflows:plan -> workflows/plan.toml
  const namespace = parts[0]
  const commandName = parts.slice(1).join("-")
  return `${namespace}/${commandName}.toml`
}

/**
 * 清理命令名，防止路径遍历攻击
 * 注意：保留 `:` 作为命名空间分隔符
 */
function sanitizeCommandName(name: string): string {
  return name
    .replace(/\.\./g, "") // 移除 ..
    .replace(/[/\\]/g, "-") // 替换路径分隔符
    .replace(/[<>"|?*\x00-\x1f]/g, "") // 移除 Windows 非法文件名字符（保留 : 用于命名空间）
    .replace(/^\.+/, "") // 移除开头的点
    .replace(/\.+$/, "") // 移除结尾的点
    .replace(/^-+$/, "") // 如果只剩下横杠，视为空
    .replace(/-+/g, "-") // 合并连续横杠
    .replace(/^-|-$/g, "") // 移除首尾横杠
}

/**
 * 构建命令的 prompt 内容
 */
function buildCommandPrompt(cmd: ClaudeCommand): string {
  const body = cmd.body?.trim() || ""
  const header = cmd.argumentHint ? "## Arguments" : "## User Input"
  const argLine = cmd.argumentHint ? `${cmd.argumentHint}: {{args}}` : "{{args}}"
  return [body, "", header, argLine].filter(Boolean).join("\n")
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
  const { name, description, version } = plugin.manifest
  return [
    "# System Context",
    "",
    `- Project: ${name}`,
    `- Description: ${description || "(not provided in plugin manifest)"}`,
    ...(version ? [`- Version: ${version}`] : []),
  ]
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
  const name = command.name.startsWith("/") ? command.name : `/${command.name}`
  const details = [
    command.description,
    command.argumentHint && `Arguments: ${command.argumentHint}`,
    command.allowedTools?.length && `Allowed tools: ${command.allowedTools.join(", ")}`,
  ].filter(Boolean)

  return `- To run \`${name}\`: ${details.join(" ") || "No description or metadata provided."}`
}

function demoteHeadings(markdown: string): string {
  return markdown
    .split("\n")
    .map((line) => line.replace(/^(#{1,5})(\s+)/, (_match, hashes: string, space: string) => `#${hashes}${space}`))
    .join("\n")
}
