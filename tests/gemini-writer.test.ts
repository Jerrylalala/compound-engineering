import { describe, expect, test } from "bun:test"
import { promises as fs } from "fs"
import os from "os"
import path from "path"
import { writeGeminiBundle } from "../src/targets/gemini"
import type { GeminiBundle } from "../src/types/gemini"

async function exists(filePath: string): Promise<boolean> {
  try {
    await fs.access(filePath)
    return true
  } catch {
    return false
  }
}

describe("writeGeminiBundle", () => {
  test("writes GEMINI.md under .gemini", async () => {
    const tempRoot = await fs.mkdtemp(path.join(os.tmpdir(), "gemini-test-"))
    const bundle: GeminiBundle = {
      geminiMd: "# System Context\n",
    }

    await writeGeminiBundle(tempRoot, bundle)

    const geminiPath = path.join(tempRoot, ".gemini", "GEMINI.md")
    expect(await exists(geminiPath)).toBe(true)
  })

  test("writes directly into a .gemini output root", async () => {
    const tempRoot = await fs.mkdtemp(path.join(os.tmpdir(), "gemini-root-"))
    const geminiRoot = path.join(tempRoot, ".gemini")
    await fs.mkdir(geminiRoot, { recursive: true })
    const bundle: GeminiBundle = {
      geminiMd: "# System Context\n",
    }

    await writeGeminiBundle(geminiRoot, bundle)

    const geminiPath = path.join(geminiRoot, "GEMINI.md")
    expect(await exists(geminiPath)).toBe(true)
  })
})
