import path from "path"
import { ensureDir, writeText } from "../utils/files"
import type { GeminiBundle, GeminiCommand } from "../types/gemini"

export async function writeGeminiBundle(outputRoot: string, bundle: GeminiBundle): Promise<void> {
  const geminiRoot = resolveGeminiRoot(outputRoot)
  await ensureDir(geminiRoot)

  // 写入 GEMINI.md（系统上下文）
  await writeText(path.join(geminiRoot, "GEMINI.md"), bundle.geminiMd.trimEnd() + "\n")

  // 写入命令 TOML 文件
  const commandsRoot = path.join(geminiRoot, "commands")
  await ensureDir(commandsRoot)

  for (const cmd of bundle.commands) {
    const tomlPath = path.join(commandsRoot, cmd.relativePath)

    // P1 修复：验证路径在 commands 目录内，防止路径遍历攻击
    const resolvedPath = path.resolve(tomlPath)
    const resolvedRoot = path.resolve(commandsRoot)
    if (!resolvedPath.startsWith(resolvedRoot + path.sep) && resolvedPath !== resolvedRoot) {
      throw new Error(`路径遍历检测，拒绝写入: ${cmd.relativePath}`)
    }

    const tomlDir = path.dirname(tomlPath)
    await ensureDir(tomlDir)
    await writeText(tomlPath, renderCommandToml(cmd))
  }
}

/**
 * 将命令转换为 TOML 格式
 */
function renderCommandToml(cmd: GeminiCommand): string {
  const escapedDescription = escapeTomlString(cmd.description)
  const escapedPrompt = escapeTomlMultilineString(cmd.prompt)

  return `# Gemini CLI command: /${cmd.name}
# Auto-generated from Claude Code plugin

description = "${escapedDescription}"

prompt = """
${escapedPrompt}
"""
`
}

/**
 * 转义 TOML 基本字符串中的特殊字符（用于 description 等单行字段）
 */
function escapeTomlString(str: string): string {
  return str
    .replace(/\\/g, "\\\\")
    .replace(/"/g, '\\"')
    .replace(/\n/g, "\\n")
    .replace(/\r/g, "\\r")
    .replace(/\t/g, "\\t")
    .replace(/[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/g, "") // 移除不可打印控制字符
}

/**
 * 转义 TOML 多行字符串中的特殊字符（用于 prompt 字段）
 * TOML 多行字符串使用 """ 包裹，需要转义内容中的 """ 序列
 */
function escapeTomlMultilineString(str: string): string {
  // 转义反斜杠（必须先做）
  let result = str.replace(/\\/g, "\\\\")
  // 转义连续的三个引号，防止提前关闭多行字符串
  result = result.replace(/"""/g, '""\\\"')
  // 移除不可打印控制字符（保留换行、回车、制表符）
  result = result.replace(/[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/g, "")
  return result
}

function resolveGeminiRoot(outputRoot: string): string {
  return path.basename(outputRoot) === ".gemini" ? outputRoot : path.join(outputRoot, ".gemini")
}
