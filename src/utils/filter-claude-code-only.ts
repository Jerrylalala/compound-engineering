/**
 * 过滤 Claude Code 专属内容
 *
 * 用于转换到 Codex/Gemini 格式时移除仅在 Claude Code 中有意义的内容：
 * - <!-- CLAUDE-CODE-ONLY-START --> ... <!-- CLAUDE-CODE-ONLY-END --> 块
 * - [C] 和 [G] 参数标记
 *
 * 这些内容在 Claude Code 中用于调用其他 AI 工具，
 * 但转换后的版本本身就是那个工具，不需要"调用自己"。
 */
export function filterClaudeCodeOnly(content: string): string {
  if (!content) return ""
  if (typeof content !== "string") {
    console.warn(`[filter-claude-code-only] 收到非字符串输入 (${typeof content})，强制转换`)
    return String(content)
  }

  let result = content

  // 移除 CLAUDE-CODE-ONLY 块
  // 匹配：<!-- CLAUDE-CODE-ONLY-START --> 任意内容 <!-- CLAUDE-CODE-ONLY-END -->
  const blockPattern = /<!--\s*CLAUDE-CODE-ONLY-START\s*-->[\s\S]*?<!--\s*CLAUDE-CODE-ONLY-END\s*-->/gi
  result = result.replace(blockPattern, "")

  // 移除 [C] 和 [G] 参数标记（包括前后可能的空格）
  // 这些在转换后的工具中没有意义
  result = result.replace(/\[C\]\s*/gi, "")
  result = result.replace(/\[G\]\s*/gi, "")

  // 清理多余的连续空行（保留最多 2 个换行）
  result = result.replace(/\n{3,}/g, "\n\n")

  // 清理行首行尾的多余空白
  result = result.trim()

  return result
}
