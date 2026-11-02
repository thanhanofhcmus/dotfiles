# Git commits

- Keep commit messages short. Follow the repo's existing commit convention (check `git log`); if it has none, use Conventional Commits (`type(scope): summary`).
- In the main checkout of a repo (not a git worktree), never commit on your own; leave changes uncommitted unless I explicitly ask.
- Inside a git worktree, the main agent and subagents may commit freely.

# Commands for me to run

- When I ask for a command to run myself, also copy it to my clipboard as a single line and confirm by reading the clipboard back:
  - Linux: `printf '%s' "<cmd>" | wl-copy`, confirm with `wl-paste`.
  - macOS: `printf '%s' "<cmd>" | pbcopy`, confirm with `pbpaste`.
  - Check `uname` if you're not sure which machine you're on.
