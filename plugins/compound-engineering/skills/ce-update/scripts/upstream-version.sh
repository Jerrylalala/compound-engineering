#!/usr/bin/env bash
# Print the public repository `version` field from
# plugins/compound-engineering/.claude-plugin/plugin.json on main, or the
# literal sentinel `__CE_UPDATE_VERSION_FAILED__` if the lookup fails.
#
# Compared to release tags, this reads the current main HEAD because the
# marketplace installs plugin contents from main HEAD; comparing against tags
# false-positives whenever main is ahead of the last tag.

set -u

RAW_URL="https://raw.githubusercontent.com/Jerrylalala/compound-engineering/main/plugins/compound-engineering/.claude-plugin/plugin.json"

json=""

if command -v gh >/dev/null 2>&1; then
  json=$(gh api repos/Jerrylalala/compound-engineering/contents/plugins/compound-engineering/.claude-plugin/plugin.json --jq '.content | @base64d' 2>/dev/null || true)
fi

if [ -z "$json" ] && command -v curl >/dev/null 2>&1; then
  json=$(curl -fsSL "$RAW_URL" 2>/dev/null || true)
fi

version=""

if [ -n "$json" ] && command -v python3 >/dev/null 2>&1; then
  version=$(printf '%s' "$json" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("version", ""))' 2>/dev/null || true)
elif [ -n "$json" ] && command -v python >/dev/null 2>&1; then
  version=$(printf '%s' "$json" | python -c 'import json,sys; print(json.load(sys.stdin).get("version", ""))' 2>/dev/null || true)
elif [ -n "$json" ] && command -v node >/dev/null 2>&1; then
  version=$(printf '%s' "$json" | node -e 'let input=""; process.stdin.on("data", d => input += d); process.stdin.on("end", () => { try { console.log(JSON.parse(input).version || ""); } catch { process.exit(1); } });' 2>/dev/null || true)
fi

if [ -n "$version" ]; then
  echo "$version"
else
  echo '__CE_UPDATE_VERSION_FAILED__'
fi
