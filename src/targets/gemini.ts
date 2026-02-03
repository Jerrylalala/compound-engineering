import path from "path"
import { ensureDir, writeText } from "../utils/files"
import type { GeminiBundle } from "../types/gemini"

export async function writeGeminiBundle(outputRoot: string, bundle: GeminiBundle): Promise<void> {
  const geminiRoot = resolveGeminiRoot(outputRoot)
  await ensureDir(geminiRoot)
  await writeText(path.join(geminiRoot, "GEMINI.md"), bundle.geminiMd.trimEnd() + "\n")
}

function resolveGeminiRoot(outputRoot: string): string {
  return path.basename(outputRoot) === ".gemini" ? outputRoot : path.join(outputRoot, ".gemini")
}
