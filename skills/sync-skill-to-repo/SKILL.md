---
name: sync-skill-to-repo
description: Sync a specific skill from your global ~/.agents/skills directory to the 'dev-skills' repository. Supports full Git workflow (branch, commit, push, PR). Use when you want to update the 'dev-skills' repo with improvements made to global skills.
---

# Sync Skill to Repo

This skill allows you to import a single skill from your global `~/.agents/skills` directory into your `dev-skills` repository (`~/Documents/dev-skills/`).

## Quick start

To sync a skill **without** Git operations:

```bash
bash ./skills/sync-skill-to-repo/scripts/sync_to_repo.sh <skill-name>
```

To sync a skill **with** a full Git workflow (checkout, commit, push, PR) in the target repo:

```bash
bash ./skills/sync-skill-to-repo/scripts/sync_to_repo.sh <skill-name> --git
```

## Workflow

1. Identify a global skill you want to sync back to the `dev-skills` repo.
2. Run the sync script.
3. If `--git` is used:
   - A new branch `sync-skill-<name>-<timestamp>` is created in `~/Documents/dev-skills/`.
   - The skill is synced to `~/Documents/dev-skills/skills/<name>`.
   - Changes are committed and pushed to the `dev-skills` remote.
   - A Pull Request is created in the `dev-skills` repository.

## Note

- Requires `rsync` for syncing.
- Requires `git` and optionally `gh` CLI for the full workflow.
- Target repository is hardcoded to `~/Documents/dev-skills/`.
