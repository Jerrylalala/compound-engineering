import path from "path"
import fs from "fs/promises"
import type { ClaudeSkill } from "../types/claude"
import { copyDir, ensureDir, pathExists, readJson, sanitizePathName, writeJson } from "../utils/files"
import { forceDirectorySymlink, isValidSkillName } from "../utils/symlink"

const COPIED_SKILL_MARKER = ".compound-plugin-skill.json"

export async function syncSkills(
  skills: ClaudeSkill[],
  skillsDir: string,
): Promise<void> {
  await ensureDir(skillsDir)

  const seen = new Set<string>()
  for (const skill of skills) {
    if (!isValidSkillName(skill.name)) {
      console.warn(`Skipping skill with invalid name: ${skill.name}`)
      continue
    }

    const safeName = sanitizePathName(skill.name)
    if (seen.has(safeName)) {
      console.warn(`Skipping skill "${skill.name}": sanitized name "${safeName}" collides with another skill`)
      continue
    }
    seen.add(safeName)

    const target = path.join(skillsDir, safeName)
    await syncSkillDir(skill.sourceDir, target)
  }
}

async function syncSkillDir(sourceDir: string, target: string): Promise<void> {
  try {
    const symlinkResult = await forceDirectorySymlink(sourceDir, target)
    if (symlinkResult === "linked") return
    if (!(await isManagedCopiedSkill(target, sourceDir))) return
    await fs.rm(target, { recursive: true, force: true })
    const retryResult = await forceDirectorySymlink(sourceDir, target)
    if (retryResult === "linked") return
  } catch (err) {
    if (!isSymlinkPrivilegeError(err)) throw err

    if (await pathExists(target)) {
      const stat = await fs.lstat(target)
      if (stat.isSymbolicLink()) {
        await fs.unlink(target)
      } else if (stat.isDirectory()) {
        if (!(await isManagedCopiedSkill(target, sourceDir))) {
          console.warn(`Skipping ${target}: a real directory exists there (remove it manually to replace with a copy).`)
          return
        }
        await fs.rm(target, { recursive: true, force: true })
      } else {
        await fs.unlink(target)
      }
    }
    await copyDir(sourceDir, target)
    await writeJson(path.join(target, COPIED_SKILL_MARKER), {
      managedBy: "compound-plugin",
      sourceDir: path.resolve(sourceDir),
    })
  }
}

async function isManagedCopiedSkill(target: string, sourceDir: string): Promise<boolean> {
  try {
    const marker = await readJson<{ managedBy?: string, sourceDir?: string }>(path.join(target, COPIED_SKILL_MARKER))
    return marker.managedBy === "compound-plugin" || marker.sourceDir === path.resolve(sourceDir)
  } catch {
    return false
  }
}

function isSymlinkPrivilegeError(err: unknown): boolean {
  const code = (err as NodeJS.ErrnoException).code
  return code === "EPERM" || code === "EACCES"
}
