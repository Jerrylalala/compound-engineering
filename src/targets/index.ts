import type { ClaudePlugin } from "../types/claude"
import type { OpenCodeBundle } from "../types/opencode"
import type { CodexBundle } from "../types/codex"
import type { GeminiBundle } from "../types/gemini"
import { convertClaudeToOpenCode, type ClaudeToOpenCodeOptions } from "../converters/claude-to-opencode"
import { convertClaudeToCodex } from "../converters/claude-to-codex"
import { convertClaudeToGemini } from "../converters/claude-to-gemini"
import { writeOpenCodeBundle } from "./opencode"
import { writeCodexBundle } from "./codex"
import { writeGeminiBundle } from "./gemini"

export type TargetHandler<TBundle = unknown> = {
  name: string
  implemented: boolean
  convert: (plugin: ClaudePlugin, options: ClaudeToOpenCodeOptions) => TBundle | null
  write: (outputRoot: string, bundle: TBundle) => Promise<void>
}

export const targets: Record<string, TargetHandler> = {
  opencode: {
    name: "opencode",
    implemented: true,
    convert: convertClaudeToOpenCode,
    write: writeOpenCodeBundle,
  },
  codex: {
    name: "codex",
    implemented: true,
    convert: convertClaudeToCodex as TargetHandler<CodexBundle>["convert"],
    write: writeCodexBundle as TargetHandler<CodexBundle>["write"],
  },
  gemini: {
    name: "gemini",
    implemented: true,
    convert: convertClaudeToGemini as TargetHandler<GeminiBundle>["convert"],
    write: writeGeminiBundle as TargetHandler<GeminiBundle>["write"],
  },
}
