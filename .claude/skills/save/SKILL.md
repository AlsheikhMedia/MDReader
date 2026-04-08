---
name: save
description: End-of-session progress saver for MDReader. Updates auto-memory, optionally refreshes CLAUDE.md, then commits and asks about pushing. Use when the user says "save", "save progress", "wrap up", "end session", or "let's stop here".
disable-model-invocation: true
metadata:
  author: AlsheikhMedia
  version: 1.0.0
  adapted-from: helpyard.ae save skill v1.0.0
---

# Save Progress (MDReader)

You are performing an end-of-session save. Complete ALL applicable steps below in order. Do not skip a step unless its precondition says you may.

---

## Step 1: Update Auto-Memory

The auto-memory directory for this project is provided by your harness in the system prompt's **auto memory** section — use whichever path the harness gave you for this session. (At time of writing, on Linux it resolves to `$HOME/.claude/projects/-home-<user>-Downloads-00dev-MDReader/memory/`, but never hardcode that — always read it from your system prompt so the skill works on any machine and any user account.)

Read `MEMORY.md` from that directory (it may not exist yet — if so, the directory may also need creating).

Decide what from this session is worth persisting across future conversations, using the auto-memory rules from your system prompt:

- **user** memories — newly learned facts about how Hassan works
- **feedback** memories — corrections or validated approaches with **Why:** and **How to apply:** lines
- **project** memories — decisions, deadlines, motivations not derivable from code/git
- **reference** memories — pointers to external systems (Codeberg, GitHub, Homebrew tap)

For each new fact, write it to its own file (e.g. `feedback_commits.md`, `reference_codeberg.md`) with the standard frontmatter (`name`, `description`, `type`), then add a one-line pointer to `MEMORY.md`.

**Do NOT** save:
- Code patterns, file paths, architecture (already in `CLAUDE.md` / source)
- Recent commit history (in `git log`)
- Ephemeral session state
- Anything redundant with `CLAUDE.md`

Keep `MEMORY.md` under 200 lines.

---

## Step 2: Update CLAUDE.md (only if needed)

`CLAUDE.md` at the repo root is the stable project reference doc. Update it **only** if this session changed something it documents:

- Build/test commands
- Architecture or major file layout
- Distribution targets (GitHub repo URL, homebrew tap, releases)
- Key patterns / conventions that future sessions need to know

**Do NOT** touch `CLAUDE.md` for routine bug fixes, refactors, CI tweaks, or work it doesn't already cover. If unsure, leave it alone.

If you do edit it, keep changes minimal and surgical.

---

## Step 3: Git Commit

1. Run `git status` to see all changes (never use `-uall`).
2. Run `git diff --stat HEAD` to see scope.
3. Stage **specific files by name** — never `git add .` or `git add -A` (would risk staging `.env` if `.gitignore` ever broke).
4. Confirm `.env` is **not** staged before committing. If it is, stop and investigate `.gitignore`.
5. Write a clear commit message describing the session's work — focus on the *why*, not just the *what*.
6. Commit with co-author trailer:

   ```
   Co-Authored-By: Claude <noreply@anthropic.com>
   ```

The local git identity for this clone is already configured (`Hassan Alsheikh <58526066+HassanAlsheikh@users.noreply.github.com>`).

---

## Step 4: Ask About Push

After committing, ask the user:

> Committed. Want me to push to `origin/main`? (This will auto-mirror to Codeberg via the GitHub Action.)

Wait for their answer. Do NOT push without explicit confirmation.

If they say yes:
- `git push origin main`
- The `.github/workflows/mirror-to-codeberg.yml` workflow will run automatically and sync the push to Codeberg within seconds.
- Optionally verify with: `gh run list --workflow mirror-to-codeberg.yml --repo AlsheikhMedia/MDReader --limit 1`

**Never** push directly to the `codeberg` remote — it's there as a fallback, but routine sync goes through the GitHub Action so the two stay in lockstep.

---

## Anti-Patterns

- Do NOT push without asking.
- Do NOT push to `codeberg` remote directly during routine save — let the mirror workflow do it.
- Do NOT stage `.env` or any file matching `.env.*` (except a committed `.env.example` template if one exists).
- Do NOT use `git add .` / `git add -A` — name files explicitly.
- Do NOT bloat `MEMORY.md` past 200 lines — split into topic files and link from the index.
- Do NOT update `CLAUDE.md` with speculative or planned work — only what's actually true now.
- Do NOT save memories that duplicate `CLAUDE.md` content or that are derivable from `git log`.
- Do NOT create new doc files unless the work genuinely warrants it.
