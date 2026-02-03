import { describe, expect, test } from "bun:test"
import { promises as fs } from "fs"
import os from "os"
import path from "path"
import { writeGeminiBundle } from "../src/targets/gemini"
import type { GeminiBundle } from "../src/types/gemini"
import { exists } from "./utils/fs"

describe("writeGeminiBundle", () => {
  test("writes GEMINI.md under .gemini", async () => {
    const tempRoot = await fs.mkdtemp(path.join(os.tmpdir(), "gemini-test-"))
    const bundle: GeminiBundle = {
      geminiMd: "# System Context\n",
      commands: [],
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
      commands: [],
    }

    await writeGeminiBundle(geminiRoot, bundle)

    const geminiPath = path.join(geminiRoot, "GEMINI.md")
    expect(await exists(geminiPath)).toBe(true)
  })

  test("writes command TOML files under commands directory", async () => {
    const tempRoot = await fs.mkdtemp(path.join(os.tmpdir(), "gemini-cmd-"))
    const bundle: GeminiBundle = {
      geminiMd: "# System Context\n",
      commands: [
        {
          name: "workflows:plan",
          description: "Plan the work.",
          prompt: "Create a plan.\n\n## Arguments\n[FOCUS]: {{args}}",
          relativePath: "workflows/plan.toml",
        },
        {
          name: "test-command",
          description: "A test command.",
          prompt: "Test prompt.\n\n## User Input\n{{args}}",
          relativePath: "test-command.toml",
        },
      ],
    }

    await writeGeminiBundle(tempRoot, bundle)

    // 验证命令目录和文件
    const commandsDir = path.join(tempRoot, ".gemini", "commands")
    expect(await exists(commandsDir)).toBe(true)

    const planPath = path.join(commandsDir, "workflows", "plan.toml")
    expect(await exists(planPath)).toBe(true)

    const testPath = path.join(commandsDir, "test-command.toml")
    expect(await exists(testPath)).toBe(true)

    // 验证 TOML 内容
    const planContent = await fs.readFile(planPath, "utf-8")
    expect(planContent).toContain('description = "Plan the work."')
    expect(planContent).toContain("prompt = ")
    expect(planContent).toContain("{{args}}")
  })

  test("escapes triple quotes in prompt content to prevent TOML injection", async () => {
    const tempRoot = await fs.mkdtemp(path.join(os.tmpdir(), "gemini-escape-"))
    const bundle: GeminiBundle = {
      geminiMd: "# System Context\n",
      commands: [
        {
          name: "inject-test",
          description: 'Test with "quotes"',
          prompt: 'Content with """ triple quotes """ and more text',
          relativePath: "inject-test.toml",
        },
      ],
    }

    await writeGeminiBundle(tempRoot, bundle)

    const tomlPath = path.join(tempRoot, ".gemini", "commands", "inject-test.toml")
    const content = await fs.readFile(tomlPath, "utf-8")

    // 描述中的引号应被转义
    expect(content).toContain('description = "Test with \\"quotes\\""')
    // 多行字符串中的 """ 应被转义，不应导致提前关闭
    expect(content).not.toMatch(/"""\s*"""\s*"""/)
  })

  test("handles edge cases: content ending with quotes", async () => {
    const tempRoot = await fs.mkdtemp(path.join(os.tmpdir(), "gemini-edge-"))
    const bundle: GeminiBundle = {
      geminiMd: "# System Context\n",
      commands: [
        {
          name: "edge-single",
          description: "Edge case test",
          prompt: 'Content ending with single quote"',
          relativePath: "edge-single.toml",
        },
        {
          name: "edge-double",
          description: "Edge case test",
          prompt: 'Content ending with double quotes""',
          relativePath: "edge-double.toml",
        },
        {
          name: "edge-backslash",
          description: "Edge case test",
          prompt: 'Content with backslash before triple quotes \\"""',
          relativePath: "edge-backslash.toml",
        },
      ],
    }

    await writeGeminiBundle(tempRoot, bundle)

    // 验证所有文件都能正确生成
    const singlePath = path.join(tempRoot, ".gemini", "commands", "edge-single.toml")
    const doublePath = path.join(tempRoot, ".gemini", "commands", "edge-double.toml")
    const backslashPath = path.join(tempRoot, ".gemini", "commands", "edge-backslash.toml")

    expect(await exists(singlePath)).toBe(true)
    expect(await exists(doublePath)).toBe(true)
    expect(await exists(backslashPath)).toBe(true)

    // 验证内容格式正确（以 """ 结尾）
    const singleContent = await fs.readFile(singlePath, "utf-8")
    const doubleContent = await fs.readFile(doublePath, "utf-8")

    // 每个文件应该以正确的 """ 结尾
    expect(singleContent.trim().endsWith('"""')).toBe(true)
    expect(doubleContent.trim().endsWith('"""')).toBe(true)
  })
})
