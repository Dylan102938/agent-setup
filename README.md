# agent-setup

Single source of truth for agent instructions and skills across all coding harnesses on this machine.

```
AGENTS.md      # global instructions (installed as CLAUDE.md / AGENTS.md per harness)
skills/        # shared skills, one directory per skill
modules.yaml   # external modules (e.g. dstore) that install themselves
modules/       # gitignored clones of the above
install.sh     # symlinks skills/instructions, then installs modules
```

## Install

```sh
./install.sh
```

This symlinks `AGENTS.md` and every skill into each harness found on the machine:

| Harness     | Instructions                    | Skills                      |
| ----------- | ------------------------------- | --------------------------- |
| Claude Code | `~/.claude/CLAUDE.md`           | `~/.claude/skills/`         |
| Codex       | `~/.codex/AGENTS.md`            | `~/.codex/skills/`          |
| OpenCode    | `~/.config/opencode/AGENTS.md`  | `~/.config/opencode/skill/` |

Because everything is symlinked, editing files in this repo (or `git pull`) updates all harnesses immediately — re-running `install.sh` is only needed when a *new* skill is added. Pre-existing real files are backed up to `~/.agent-setup-backup/<timestamp>/` before being replaced.

## External modules

Tools that manage their own harness artifacts (harness-specific skills, hooks, databases) are declared in `modules.yaml` rather than vendored into `skills/`:

```yaml
modules:
  - repo: git@github.com:Dylan102938/dstore.git
    ref: main                                   # optional: pin a branch/tag/SHA
    install: uv sync && uv run dstore install dsync
```

`install.sh` clones each repo into `modules/<name>` (gitignored), fast-forwards it (or checks out `ref`), and runs its `install` command inside the clone. Plain clones are used instead of git submodules: modules version themselves and expose their own installers, so there is nothing worth pinning in this repo's history — and `ref` covers the cases where there is.

## Notes

- Harness-specific skills managed by other tools (e.g. dstore's `dsync`) are left untouched; only skills present in `skills/` are linked.
- To add a harness, append a `"<dir>:<instructions filename>:<skills dirname>"` entry to `HARNESSES` in `install.sh`.
