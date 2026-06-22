#!/bin/bash
TARGET_DIR="$HOME/.agents"
GEMINI_DIR="$HOME/.gemini"
SOURCE_DIR="${1:-.}"
mkdir -p "$TARGET_DIR/skills" "$TARGET_DIR/agents" "$TARGET_DIR/commands" "$TARGET_DIR/rules"
mkdir -p "$GEMINI_DIR/skills"
echo "Syncing from $SOURCE_DIR..."
if [ -d "$SOURCE_DIR/skills" ]; then
    for d in "$SOURCE_DIR/skills"/*/; do
        if [ -f "$d/SKILL.md" ]; then
            name=$(basename "$d")
            echo "  skill   [syncing] $name"
            mkdir -p "$TARGET_DIR/skills/$name"
            cp -r "$d"* "$TARGET_DIR/skills/$name/"
            mkdir -p "$GEMINI_DIR/skills/$name"
            cp -r "$d"* "$GEMINI_DIR/skills/$name/"
        fi
    done
fi
for type in agents commands rules; do
    if [ -d "$SOURCE_DIR/$type" ]; then
        echo "  $type [syncing] all"
        cp -r "$SOURCE_DIR/$type/"* "$TARGET_DIR/$type/"
    fi
done
echo "Done. Assets are now globally available in ~/.agents and ~/.gemini."
