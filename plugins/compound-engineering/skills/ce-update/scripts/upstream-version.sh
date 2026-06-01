#!/usr/bin/env bash
# Print the public repository `version` field from
# plugins/compound-engineering/.claude-plugin/plugin.json on main, or the
# literal sentinel `__CE_UPDATE_VERSION_FAILED__` if the lookup fails.
#
# Compared to release tags, this reads the current main HEAD because the
# marketplace installs plugin contents from main HEAD; comparing against tags
# false-positives whenever main is ahead of the last tag.

set -u

CONTENTS_URL="https://api.github.com/repos/Jerrylalala/compound-engineering/contents/plugins/compound-engineering/.claude-plugin/plugin.json?ref=main"

json=""
api_json=""

if command -v gh >/dev/null 2>&1; then
  json=$(gh api repos/Jerrylalala/compound-engineering/contents/plugins/compound-engineering/.claude-plugin/plugin.json --jq '.content | @base64d' 2>/dev/null || true)
fi

if [ -z "$json" ] && command -v curl >/dev/null 2>&1; then
  api_json=$(curl --retry 3 --retry-delay 2 --retry-all-errors -fsSL -H "Accept: application/vnd.github+json" -H "Cache-Control: no-cache" "$CONTENTS_URL" 2>/dev/null || true)
fi

version=""

payload="$json"
payload_kind="plugin"

if [ -z "$payload" ] && [ -n "$api_json" ]; then
  payload="$api_json"
  payload_kind="contents"
fi

if [ -n "$payload" ] && command -v python3 >/dev/null 2>&1; then
  version=$(printf '%s' "$payload" | python3 -c 'import base64,json,sys; kind=sys.argv[1]; data=json.load(sys.stdin); data=json.loads(base64.b64decode(data["content"])) if kind == "contents" else data; print(data.get("version", ""))' "$payload_kind" 2>/dev/null || true)
elif [ -n "$payload" ] && command -v python >/dev/null 2>&1; then
  version=$(printf '%s' "$payload" | python -c 'import base64,json,sys; kind=sys.argv[1]; data=json.load(sys.stdin); data=json.loads(base64.b64decode(data["content"])) if kind == "contents" else data; print(data.get("version", ""))' "$payload_kind" 2>/dev/null || true)
elif [ -n "$payload" ] && command -v node >/dev/null 2>&1; then
  version=$(printf '%s' "$payload" | node -e 'const kind = process.argv[1]; let input=""; process.stdin.on("data", d => input += d); process.stdin.on("end", () => { try { let data = JSON.parse(input); if (kind === "contents") data = JSON.parse(Buffer.from(data.content, "base64").toString("utf8")); console.log(data.version || ""); } catch { process.exit(1); } });' "$payload_kind" 2>/dev/null || true)
fi

if [ -n "$version" ]; then
  echo "$version"
else
  echo '__CE_UPDATE_VERSION_FAILED__'
fi
