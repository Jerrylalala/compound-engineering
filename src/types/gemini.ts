export type GeminiCommand = {
  /** 命令名称，如 "workflows:plan" */
  name: string
  /** 命令描述 */
  description: string
  /** 命令的完整 prompt 内容 */
  prompt: string
  /** 命令的相对路径，如 "workflows/plan.toml" */
  relativePath: string
}

export type GeminiBundle = {
  /** GEMINI.md 系统上下文内容 */
  geminiMd: string
  /** 命令 TOML 文件列表 */
  commands: GeminiCommand[]
}
