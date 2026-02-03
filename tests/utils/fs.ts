import { promises as fs } from "fs"

/**
 * 检查文件或目录是否存在
 * 提取为共享工具函数，避免在多个测试文件中重复定义
 */
export async function exists(filePath: string): Promise<boolean> {
  try {
    await fs.access(filePath)
    return true
  } catch {
    return false
  }
}
