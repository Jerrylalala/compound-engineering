#!/usr/bin/env bash
# Resolve the review base branch and compute the merge-base for ce:review.
# Handles fork-safe remote resolution, PR metadata, and multi-fallback detection.
#
# Usage: bash references/resolve-base.sh
# Output: BASE:<sha> on success, ERROR:<message> on failure.
#
# Detects the base branch from (in priority order):
# 1. PR metadata (base ref + base repo for fork safety)
# 2. origin/HEAD symbolic ref
# 3. gh repo view defaultBranchRef
# 4. Common branch names: main, master, develop, trunk

set -euo pipefail

REVIEW_BASE_BRANCH=""
PR_BASE_REPO=""
PR_BASE_REMOTE=""
BASE_REF=""

find_github_remote_for_repo() {
  target_repo="$1"
  for remote_name in $(git remote); do
    remote_url=$(git remote get-url "$remote_name" 2>/dev/null || true)
    case "$remote_url" in
      *"github.com:$target_repo"*|*"github.com/$target_repo"*)
        echo "$remote_name"
        return 0
        ;;
    esac
  done
  return 1
}

deepen_remote_history() {
  remote_name="$1"
  git fetch --no-tags --unshallow "$remote_name" "+refs/heads/*:refs/remotes/$remote_name/*" 2>/dev/null \
    || git fetch --no-tags --deepen=2147483647 "$remote_name" "+refs/heads/*:refs/remotes/$remote_name/*" 2>/dev/null \
    || git fetch --no-tags "$remote_name" "+refs/heads/*:refs/remotes/$remote_name/*" 2>/dev/null \
    || true
}

# Step 1: Try PR metadata (handles fork workflows)
if command -v gh >/dev/null 2>&1; then
  PR_META=$(gh pr view --json baseRefName,url 2>/dev/null || true)
  if [ -n "$PR_META" ]; then
    REVIEW_BASE_BRANCH=$(echo "$PR_META" | jq -r '.baseRefName // empty' 2>/dev/null || true)
    PR_BASE_REPO=$(echo "$PR_META" | jq -r '.url // empty' 2>/dev/null | sed -n 's#https://github.com/\([^/]*/[^/]*\)/pull/.*#\1#p' || true)
  fi
fi

# Step 2: Fall back to origin/HEAD
if [ -z "$REVIEW_BASE_BRANCH" ]; then
  REVIEW_BASE_BRANCH=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)
fi

# Step 3: Fall back to gh repo view
if [ -z "$REVIEW_BASE_BRANCH" ] && command -v gh >/dev/null 2>&1; then
  REVIEW_BASE_BRANCH=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name' 2>/dev/null || true)
fi

# Step 4: Fall back to common branch names
if [ -z "$REVIEW_BASE_BRANCH" ]; then
  for candidate in main master develop trunk; do
    if git rev-parse --verify "origin/$candidate" >/dev/null 2>&1 || git rev-parse --verify "$candidate" >/dev/null 2>&1; then
      REVIEW_BASE_BRANCH="$candidate"
      break
    fi
  done
fi

# Resolve the base ref from the correct remote (fork-safe)
if [ -n "$REVIEW_BASE_BRANCH" ]; then
  if [ -n "$PR_BASE_REPO" ]; then
    PR_BASE_REMOTE=$(find_github_remote_for_repo "$PR_BASE_REPO" || true)
    if [ -n "$PR_BASE_REMOTE" ]; then
      git rev-parse --verify "$PR_BASE_REMOTE/$REVIEW_BASE_BRANCH" >/dev/null 2>&1 || git fetch --no-tags "$PR_BASE_REMOTE" "$REVIEW_BASE_BRANCH:refs/remotes/$PR_BASE_REMOTE/$REVIEW_BASE_BRANCH" 2>/dev/null || git fetch --no-tags "$PR_BASE_REMOTE" "$REVIEW_BASE_BRANCH" 2>/dev/null || true
      BASE_REF=$(git rev-parse --verify "$PR_BASE_REMOTE/$REVIEW_BASE_BRANCH" 2>/dev/null || true)
    else
      PR_BASE_URL="https://github.com/$PR_BASE_REPO.git"
      if git fetch --no-tags "$PR_BASE_URL" "$REVIEW_BASE_BRANCH" 2>/dev/null; then
        BASE_REF=$(git rev-parse --verify FETCH_HEAD 2>/dev/null || true)
      fi
    fi
  fi
  if [ -z "$BASE_REF" ]; then
    if git remote get-url origin >/dev/null 2>&1; then
      git rev-parse --verify "origin/$REVIEW_BASE_BRANCH" >/dev/null 2>&1 || git fetch --no-tags origin "$REVIEW_BASE_BRANCH:refs/remotes/origin/$REVIEW_BASE_BRANCH" 2>/dev/null || git fetch --no-tags origin "$REVIEW_BASE_BRANCH" 2>/dev/null || true
      BASE_REF=$(git rev-parse --verify "origin/$REVIEW_BASE_BRANCH" 2>/dev/null || true)
    fi
    if [ -z "$BASE_REF" ]; then
      BASE_REF=$(git rev-parse --verify "$REVIEW_BASE_BRANCH" 2>/dev/null || true)
    fi
  fi
fi

# Compute merge-base
if [ -n "$BASE_REF" ]; then
  BASE=$(git merge-base HEAD "$BASE_REF" 2>/dev/null) || BASE=""
  if [ -z "$BASE" ] && [ "$(git rev-parse --is-shallow-repository 2>/dev/null || echo false)" = "true" ]; then
    if git remote get-url origin >/dev/null 2>&1; then
      deepen_remote_history origin
      BASE=$(git merge-base HEAD "$BASE_REF" 2>/dev/null) || BASE=""
    fi
    if [ -z "$BASE" ] && [ -n "$PR_BASE_REMOTE" ] && [ "$PR_BASE_REMOTE" != "origin" ]; then
      deepen_remote_history "$PR_BASE_REMOTE"
      BASE=$(git merge-base HEAD "$BASE_REF" 2>/dev/null) || BASE=""
    fi
  fi
  if [ -z "$BASE" ]; then
    BASE=""
  fi
else
  BASE=""
fi

if [ -n "$BASE" ]; then
  echo "BASE:$BASE"
else
  echo "ERROR:Unable to resolve review base branch locally. Fetch the base branch and rerun, or provide a PR number so the review scope can be determined from PR metadata."
fi
