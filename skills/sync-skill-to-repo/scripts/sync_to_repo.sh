#!/bin/bash

# Sync a specific skill from ~/.agents/skills to the dev-skills repo.
# Handles Git operations (checkout, commit, push, PR) in the target repo.

SKILL_NAME=$1
GIT_FLOW=false
TARGET_REPO="$HOME/Documents/dev-skills"

# Simple flag parsing
shift
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --git) GIT_FLOW=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$SKILL_NAME" ]; then
  echo "Error: No skill name provided."
  echo "Usage: $0 <skill-name> [--git]"
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

if [ "$GIT_FLOW" = true ]; then
    BRANCH_NAME="sync-skill-$SKILL_NAME-$(date +%Y%m%d%H%M%S)"
    echo "Creating new branch in $TARGET_REPO: $BRANCH_NAME"
    git -C "$TARGET_REPO" checkout -b "$BRANCH_NAME"
fi

mkdir -p "$TARGET_REPO/skills"

echo "Syncing '$SKILL_NAME' from global to $TARGET_REPO..."
rsync -av --delete "$SOURCE_DIR/" "$TARGET_DIR/"

if [ "$GIT_FLOW" = true ]; then
    echo "Committing and pushing changes in $TARGET_REPO..."
    git -C "$TARGET_REPO" add "skills/$SKILL_NAME"
    git -C "$TARGET_REPO" commit -m "feat: sync skill '$SKILL_NAME' from global storage"
    git -C "$TARGET_REPO" push origin "$BRANCH_NAME"
    
    if command -v gh &> /dev/null; then
        echo "Creating Pull Request for $TARGET_REPO..."
        # Run gh inside the target repo
        (cd "$TARGET_REPO" && gh pr create --title "feat: sync skill '$SKILL_NAME'" --body "Synced from ~/.agents/skills/$SKILL_NAME" --head "$BRANCH_NAME")
    else
        echo "Warning: 'gh' CLI not found. Please create PR manually."
    fi
fi

echo "✅ Skill '$SKILL_NAME' synced to $TARGET_DIR"
