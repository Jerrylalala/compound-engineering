import { describe, expect, mock, test } from "bun:test"
import { promises as fs } from "fs"
import os from "os"
import path from "path"
import type { ClaudeHomeConfig } from "../src/parsers/claude-home"
import { syncToCodex } from "../src/sync/codex"

describe("syncToCodex", () => {
  test("writes stdio and remote MCP servers into a managed block without clobbering user config", async () => {
    const tempRoot = await fs.mkdtemp(path.join(os.tmpdir(), "sync-codex-"))
    const fixtureSkillDir = path.join(import.meta.dir, "fixtures", "sample-plugin", "skills", "skill-one")
    const configPath = path.join(tempRoot, "config.toml")

    await fs.writeFile(
      configPath,
      [
        "[custom]",
        "enabled = true",
        "",
        "# BEGIN compound-plugin Claude Code MCP",
        "[mcp_servers.old]",
        "command = \"old\"",
        "# END compound-plugin Claude Code MCP",
        "",
        "[post]",
        "value = 2",
        "",
      ].join("\n"),
    )

    const config: ClaudeHomeConfig = {
      skills: [
        {
          name: "skill-one",
          sourceDir: fixtureSkillDir,
          skillPath: path.join(fixtureSkillDir, "SKILL.md"),
        },
      ],
      mcpServers: {
        local: { command: "echo", args: ["hello"], env: { KEY: "VALUE" } },
        remote: { url: "https://example.com/mcp", headers: { Authorization: "Bearer token" } },
      },
    }

    await syncToCodex(config, tempRoot)

    const skillPath = path.join(tempRoot, "skills", "skill-one")
    expect(await fs.lstat(skillPath)).toBeDefined()
    expect(await fs.readFile(path.join(skillPath, "SKILL.md"), "utf8")).toContain("name: skill-one")

    const content = await fs.readFile(configPath, "utf8")
    expect(content).toContain("[custom]")
    expect(content).toContain("[post]")
    expect(content).not.toContain("[mcp_servers.old]")
    expect(content).toContain("[mcp_servers.local]")
    expect(content).toContain("command = \"echo\"")
    expect(content).toContain("[mcp_servers.remote]")
    expect(content).toContain("url = \"https://example.com/mcp\"")
    expect(content).toContain("http_headers")
    // Old markers should be replaced with new ones
    expect(content).not.toContain("# BEGIN compound-plugin Claude Code MCP")
    expect(content.match(/# BEGIN Compound Engineering plugin MCP/g)?.length).toBe(1)

    const perms = (await fs.stat(configPath)).mode & 0o777
    if (process.platform !== "win32") {
      expect(perms).toBe(0o600)
    }
  })

  test("cleans up stale managed block when syncing with zero MCP servers", async () => {
    const tempRoot = await fs.mkdtemp(path.join(os.tmpdir(), "sync-codex-zero-"))
    const fixtureSkillDir = path.join(import.meta.dir, "fixtures", "sample-plugin", "skills", "skill-one")
    const configPath = path.join(tempRoot, "config.toml")

    // First sync with MCP servers
    const configWithServers: ClaudeHomeConfig = {
      skills: [{ name: "skill-one", sourceDir: fixtureSkillDir, skillPath: path.join(fixtureSkillDir, "SKILL.md") }],
      mcpServers: { old: { command: "old-server" } },
    }
    await syncToCodex(configWithServers, tempRoot)
    expect(await fs.readFile(configPath, "utf8")).toContain("[mcp_servers.old]")

    // Second sync with zero MCP servers
    const configEmpty: ClaudeHomeConfig = {
      skills: [{ name: "skill-one", sourceDir: fixtureSkillDir, skillPath: path.join(fixtureSkillDir, "SKILL.md") }],
      mcpServers: {},
    }
    await syncToCodex(configEmpty, tempRoot)

    const content = await fs.readFile(configPath, "utf8")
    expect(content).not.toContain("[mcp_servers.old]")
    expect(content).not.toContain("# BEGIN")
  })

  test("copies skills when symlink privileges are unavailable and refreshes managed copies", async () => {
    const tempRoot = await fs.mkdtemp(path.join(os.tmpdir(), "sync-codex-copy-"))
    const sourceRoot = await fs.mkdtemp(path.join(os.tmpdir(), "sync-codex-source-"))
    const fixtureSkillDir = path.join(sourceRoot, "skill-one")
    await fs.mkdir(fixtureSkillDir, { recursive: true })
    await fs.writeFile(path.join(fixtureSkillDir, "SKILL.md"), "---\nname: skill-one\n---\n\nv1\n")
    await fs.mkdir(path.join(fixtureSkillDir, "references"), { recursive: true })
    await fs.writeFile(path.join(fixtureSkillDir, "references", "note.md"), "note v1\n")

    const symlinkMock = mock(async () => {
      const error = new Error("privilege missing") as NodeJS.ErrnoException
      error.code = "EPERM"
      throw error
    })
    const originalSymlink = fs.symlink
    fs.symlink = symlinkMock as unknown as typeof fs.symlink

    try {
      const config: ClaudeHomeConfig = {
        skills: [
          {
            name: "skill-one",
            sourceDir: fixtureSkillDir,
            skillPath: path.join(fixtureSkillDir, "SKILL.md"),
          },
        ],
        mcpServers: {},
      }

      await syncToCodex(config, tempRoot)
      const skillPath = path.join(tempRoot, "skills", "skill-one")
      expect((await fs.lstat(skillPath)).isDirectory()).toBe(true)
      expect(await fs.readFile(path.join(skillPath, "SKILL.md"), "utf8")).toContain("v1")
      expect(await fs.readFile(path.join(skillPath, "references", "note.md"), "utf8")).toContain("note v1")

      await fs.writeFile(path.join(fixtureSkillDir, "SKILL.md"), "---\nname: skill-one\n---\n\nv2\n")
      await syncToCodex(config, tempRoot)

      const movedSourceRoot = await fs.mkdtemp(path.join(os.tmpdir(), "sync-codex-source-moved-"))
      const movedSkillDir = path.join(movedSourceRoot, "skill-one")
      await fs.mkdir(movedSkillDir, { recursive: true })
      await fs.writeFile(path.join(movedSkillDir, "SKILL.md"), "---\nname: skill-one\n---\n\nv3\n")
      await syncToCodex({
        skills: [
          {
            name: "skill-one",
            sourceDir: movedSkillDir,
            skillPath: path.join(movedSkillDir, "SKILL.md"),
          },
        ],
        mcpServers: {},
      }, tempRoot)

      expect(await fs.readFile(path.join(skillPath, "SKILL.md"), "utf8")).toContain("v3")
    } finally {
      fs.symlink = originalSymlink
    }
  })

  test("does not replace user-owned real skill directories during symlink fallback", async () => {
    const tempRoot = await fs.mkdtemp(path.join(os.tmpdir(), "sync-codex-user-dir-"))
    const fixtureSkillDir = path.join(import.meta.dir, "fixtures", "sample-plugin", "skills", "skill-one")
    const userSkillPath = path.join(tempRoot, "skills", "skill-one")
    await fs.mkdir(userSkillPath, { recursive: true })
    await fs.writeFile(path.join(userSkillPath, "SKILL.md"), "user content\n")

    const symlinkMock = mock(async () => {
      const error = new Error("privilege missing") as NodeJS.ErrnoException
      error.code = "EPERM"
      throw error
    })
    const originalSymlink = fs.symlink
    fs.symlink = symlinkMock as unknown as typeof fs.symlink

    try {
      const config: ClaudeHomeConfig = {
        skills: [
          {
            name: "skill-one",
            sourceDir: fixtureSkillDir,
            skillPath: path.join(fixtureSkillDir, "SKILL.md"),
          },
        ],
        mcpServers: {},
      }

      await syncToCodex(config, tempRoot)
      expect(await fs.readFile(path.join(userSkillPath, "SKILL.md"), "utf8")).toBe("user content\n")
    } finally {
      fs.symlink = originalSymlink
    }
  })
})
