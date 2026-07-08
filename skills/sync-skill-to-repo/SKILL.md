---
name: sync-skill-to-repo
description: Sync a specific skill from your global ~/.agents/skills directory to the 'dev-skills' repository, always via a full Git workflow (branch, commit, push, PR). Use when you want to update the 'dev-skills' repo with improvements made to global skills.
---

# Sync Skill to Repo

This skill imports a single skill from your global `~/.agents/skills` directory into your `dev-skills` repository (`~/Documents/dev-skills/`), always through a full Git workflow so every sync lands as a reviewable PR.

## Quick start

```bash
bash ./skills/sync-skill-to-repo/scripts/sync_to_repo.sh <skill-name>
```

## Workflow

1. Identify a global skill you want to sync back to the `dev-skills` repo.
2. Run the sync script. It always:
   - Checks out and pulls `main` in `~/Documents/dev-skills`.
   - Creates a new branch `sync-skill-<name>-<timestamp>`.
   - Syncs the skill to `~/Documents/dev-skills/skills/<name>` via `rsync --delete`.
   - Commits and pushes the branch.
   - Opens a Pull Request in the `dev-skills` repository (via `gh`).

## Note

- Requires `rsync` and `git`.
- Requires the `gh` CLI to open the PR automatically — without it, the branch is still pushed and a warning is printed to create the PR manually.
- Target repository is hardcoded to `~/Documents/dev-skills/`.
- Pushing and opening a PR affects shared state — confirm with the user before invoking this script, since it always creates a PR (there is no dry-run/no-git mode).
- The script always checks out `main` first. If the working tree has unrelated uncommitted changes, it auto-stashes them (`git stash push -u`) so the checkout never fails — pop the stash afterwards to get those changes back.
- If the skill is already in sync with `main` (nothing to commit), it skips the push/PR and cleans up the branch.
