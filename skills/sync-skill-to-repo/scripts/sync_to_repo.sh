#!/bin/bash
set -euo pipefail

# Sync a specific skill from ~/.agents/skills to the dev-skills repo.
# Always runs the full Git workflow (branch, commit, push, PR) in the target repo.

SKILL_NAME=$1
TARGET_REPO="$HOME/Documents/dev-skills"

if [ -z "$SKILL_NAME" ]; then
  echo "Error: No skill name provided."
  echo "Usage: $0 <skill-name>"
  exit 1
fi

SOURCE_DIR="$HOME/.agents/skills/$SKILL_NAME"
TARGET_DIR="$TARGET_REPO/skills/$SKILL_NAME"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: Skill '$SKILL_NAME' not found in $HOME/.agents/skills/"
  exit 1
fi

if [ ! -d "$TARGET_REPO" ]; then
  echo "Error: Target repository '$TARGET_REPO' not found."
  exit 1
fi

# Always land on main before branching, even if the working tree is dirty
# (e.g. unrelated in-progress edits to other skills).
if [ -n "$(git -C "$TARGET_REPO" status --porcelain)" ]; then
    STASH_MSG="sync-skill-to-repo autostash $(date +%Y%m%d%H%M%S)"
    echo "Local changes detected in $TARGET_REPO — stashing them ('$STASH_MSG') before checking out main..."
    git -C "$TARGET_REPO" stash push -u -m "$STASH_MSG"
    echo "Note: run 'git -C \"$TARGET_REPO\" stash pop' afterwards to restore your other in-progress changes."
fi

echo "Switching to main branch in $TARGET_REPO..."
git -C "$TARGET_REPO" checkout main
git -C "$TARGET_REPO" pull origin main

BRANCH_NAME="sync-skill-$SKILL_NAME-$(date +%Y%m%d%H%M%S)"
echo "Creating new branch in $TARGET_REPO: $BRANCH_NAME"
git -C "$TARGET_REPO" checkout -b "$BRANCH_NAME"

mkdir -p "$TARGET_REPO/skills"

echo "Syncing '$SKILL_NAME' from global to $TARGET_REPO..."
rsync -av --delete "$SOURCE_DIR/" "$TARGET_DIR/"

git -C "$TARGET_REPO" add "skills/$SKILL_NAME"

if git -C "$TARGET_REPO" diff --cached --quiet; then
    echo "No changes to sync for '$SKILL_NAME' — nothing to commit, skipping push/PR."
    git -C "$TARGET_REPO" checkout main
    git -C "$TARGET_REPO" branch -d "$BRANCH_NAME"
    exit 0
fi

echo "Committing and pushing changes in $TARGET_REPO..."
git -C "$TARGET_REPO" commit -m "feat: sync skill '$SKILL_NAME' from global storage"
git -C "$TARGET_REPO" push origin "$BRANCH_NAME"

if command -v gh &> /dev/null; then
    echo "Creating Pull Request for $TARGET_REPO..."
    # Run gh inside the target repo
    (cd "$TARGET_REPO" && gh pr create --title "feat: sync skill '$SKILL_NAME'" --body "Synced from ~/.agents/skills/$SKILL_NAME" --head "$BRANCH_NAME")
else
    echo "Warning: 'gh' CLI not found. Please create PR manually."
fi

echo "✅ Skill '$SKILL_NAME' synced to $TARGET_DIR and PR opened from $BRANCH_NAME"
