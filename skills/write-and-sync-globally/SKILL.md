---
name: write-and-sync-globally
description: Create, install, and sync a new Gemini CLI skill to the global dev-skills repository. Use when a user wants to build a new skill from scratch and ensure it is version-controlled globally.
---

# Write and Sync Globally

This skill automates the end-to-end process of creating a new Gemini CLI skill, installing it on the local machine, and syncing it to the `dev-skills` repository for version control and sharing.

## Workflow

### 1. Requirements Gathering
Ask the user the following questions to define the skill:
- **Task/Domain**: What core task or domain does this skill cover?
- **Use Cases**: What are 2-3 specific examples of how it will be used?
- **Resources**: Does it need executable scripts, reference documents, or assets (templates/logos)?
- **Triggers**: What specific keywords or contexts should trigger this skill?

### 2. Implementation
Follow the `skill-creator` patterns:
- **Initialize**: Use `init_skill.cjs` to create the structure.
- **Draft**: Write `SKILL.md` (keep it under 100 lines) and create any needed resources in `scripts/`, `references/`, or `assets/`.
- **Review**: Show the draft to the user and iterate.

### 3. Packaging & Installation
Once the draft is approved:
- **Package**: Run `node <path-to-skill-creator>/scripts/package_skill.cjs <skill-folder>`.
- **Install**: Run `gemini skills install <skill-name>.skill --scope user`.
- **Reload**: Notify the user to run `/skills reload` in their interactive terminal.

### 4. Global Sync
After installation, sync the skill to the `dev-skills` repository:
- Run the sync script: `bash /home/decade/.agents/skills/sync-skill-to-repo/scripts/sync_to_repo.sh <skill-name> --git`.
- This will create a branch, commit the changes, push, and create a PR in the `dev-skills` repo.

## Best Practices
- **Concise Trigger**: Ensure the `description` in `SKILL.md` is precise about when the skill should be used.
- **Script Reliability**: Test scripts before packaging if possible.
- **Progressive Disclosure**: Keep `SKILL.md` lean by moving details to `references/`.
