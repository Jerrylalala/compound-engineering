---
name: executor-capability-gate
description: "私有 Overlay：外部模型调用前置检查门控。调用 Codex/Gemini 之前运行五项检查，防止调用失败浪费时间。使用时机：任何调用外部模型（Codex [C]、Gemini [G]）之前自动运行。"
---

# Executor Capability Gate — 外部调用前置检查

> **Codex 洞察（P8，新增项）**：调用外部模型前做前置检查比"自动路由"更实用。
> 5 项检查防止无效调用，是 P7 Codex-first Executor 的前置依赖。

---

## 五项前置检查

### Check 1: CLI 安装检查

```bash
# Codex
command -v codex &>/dev/null
echo "exit: $?"  # 0=已安装, 1=未安装

# Gemini
command -v gemini &>/dev/null
```

**失败处理**：
```
❌ Codex CLI 未安装
   安装命令：npm install -g @openai/codex
   或：bun install -g @openai/codex
```

### Check 2: 登录状态检查

```bash
# Codex - 检查凭据文件是否存在（codex --version 无需登录，不能用于验证）
[ -f ~/.codex/auth.json ] && echo "OK" || echo "NOT_LOGGED_IN"

# Gemini
gemini --version 2>&1 | grep -q "version" && echo "OK" || echo "NOT_LOGGED_IN"
```

**失败处理**：
```
❌ Codex 未登录（~/.codex/auth.json 不存在）
   登录命令：codex  (首次运行引导登录)
```

### Check 3: 网络连通性检查

```bash
# 检查网络可达性（仅连通性，不含认证——凭据走 auth.json，非 OPENAI_API_KEY）
curl -s --max-time 5 "https://api.openai.com" -o /dev/null -w "%{http_code}"
# 非 000 = 网络可达（包括 401 均表示网络通）
# 000 = 网络不可达
```

**失败处理**：
```
❌ 网络不可达（curl 返回 000）
   跳过 Codex 调用，退回 Claude 执行
```

### Check 4: Rate Limit 检查

```bash
# 检查最近 Codex 调用记录（简单本地记录）
LAST_CALL=$(cat ~/.codex/.last_call 2>/dev/null || echo "0")
NOW=$(date +%s)
ELAPSED=$((NOW - LAST_CALL))

if [ $ELAPSED -lt 60 ]; then
  echo "RATE_LIMITED: 距上次调用 ${ELAPSED}s，建议等待至少 60s"
fi
```

### Check 5: 任务适配性检查

根据任务特征判断是否适合外部执行器：

| 任务特征 | Codex 适合？ | 说明 |
|---------|------------|------|
| 大量机械 patch（格式化、重命名） | ✅ 适合 | Codex 擅长批量代码操作 |
| 高风险改动（auth、payment、migration） | ❌ 不适合 | 用 Claude 主做 + review |
| 纯分析/research 任务 | ✅ 适合 | Codex 审核视角有价值 |
| 视觉/UI 任务 | ❌ 不适合 | Codex 无视觉理解能力 |
| 需要项目上下文的重构 | ⚠️ 谨慎 | Codex 缺少上下文可能误改 |

---

## 门控输出格式

每次外部调用前输出检查结果：

```
🔍 Executor Capability Gate — Codex 检查

  ✅ CLI 已安装 (codex v0.1.x)
  ✅ 已登录
  ✅ 网络正常 (API 200)
  ✅ Rate limit 正常 (距上次 120s)
  ✅ 任务适合 Codex（批量 patch）

  → 允许调用 Codex
```

或：

```
🔍 Executor Capability Gate — Codex 检查

  ✅ CLI 已安装
  ❌ Rate limit（距上次仅 30s）
  ⚠️  任务高风险（涉及 auth/payment）

  → 跳过 Codex，由 Claude 执行
     理由：rate limit + 高风险任务不适合外部执行器
```

---

## 与 [C] [G] 参数的集成

当 `ce:review [C]` 或 `ce:brainstorm [C]` 被调用时，在派发 Codex 任务前自动运行本 gate：

```
用户调用 ce:review [C]
    ↓
Executor Capability Gate 检查 Codex
    ├─ 全部通过 → 正常派发 Codex 审核
    ├─ 部分失败 → 提示原因，询问是否降级到 Claude-only
    └─ 全部失败 → 自动降级，告知用户
```

---

## 检查缓存

Gate 结果缓存 5 分钟（同一会话内）：

```bash
GATE_CACHE=~/.codex/.gate_cache
CACHE_AGE=$(( $(date +%s) - $(stat -c %Y $GATE_CACHE 2>/dev/null || echo 0) ))

if [ $CACHE_AGE -lt 300 ]; then
  # 使用缓存结果，不重新检查
  cat $GATE_CACHE
else
  # 重新检查并写入缓存
  run_gate_checks > $GATE_CACHE
fi
```
