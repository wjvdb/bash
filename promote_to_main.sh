#!/usr/bin/env bash
set -euo pipefail

# Promote a source branch to main safely.
# Usage:
#   promote_to_main [source-branch] [remote] [main-branch]
# Examples:
#   promote_to_main
#   promote_to_main security_audit
#   promote_to_main security_audit origin main

promote_to_main() {
  local SOURCE_BRANCH="${1:-$(git branch --show-current)}"
  local REMOTE="${2:-origin}"
  local MAIN_BRANCH="${3:-main}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a git repository."
  exit 1
fi

if [[ -z "${SOURCE_BRANCH}" ]]; then
  echo "Error: could not detect source branch. Pass it as the first argument."
  exit 1
fi

if ! git show-ref --verify --quiet "refs/heads/${SOURCE_BRANCH}"; then
  echo "Error: local source branch '${SOURCE_BRANCH}' does not exist."
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Error: working tree is not clean. Commit or stash changes first."
  exit 1
fi

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_TAG="backup-before-${MAIN_BRANCH}-repoint-${TIMESTAMP}"

echo "Fetching latest refs from ${REMOTE}..."
git fetch "${REMOTE}" --prune

echo "Creating local backup tag ${BACKUP_TAG} at ${SOURCE_BRANCH}..."
git tag "${BACKUP_TAG}" "${SOURCE_BRANCH}"

echo "Pushing backup tag to ${REMOTE}..."
git push "${REMOTE}" "${BACKUP_TAG}"

echo "Switching to ${MAIN_BRANCH}..."
if git show-ref --verify --quiet "refs/heads/${MAIN_BRANCH}"; then
  git switch "${MAIN_BRANCH}"
else
  git switch -c "${MAIN_BRANCH}"
fi

echo "Resetting ${MAIN_BRANCH} to ${SOURCE_BRANCH}..."
git reset --hard "${SOURCE_BRANCH}"

echo "Force-pushing ${MAIN_BRANCH} to ${REMOTE} with lease..."
git push --force-with-lease "${REMOTE}" "${MAIN_BRANCH}"

echo "Done. ${MAIN_BRANCH} now points to ${SOURCE_BRANCH}."
echo "Backup tag saved as ${BACKUP_TAG}."
}