#!/usr/bin/env bash
# Symlink AGENTS.md and skills/ into every agent harness on this machine.
# Idempotent: safe to re-run after adding skills or editing AGENTS.md.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.agent-setup-backup/$(date +%Y%m%d-%H%M%S)"

# target harnesses: "<harness dir>:<instructions filename>:<skills dirname>"
HARNESSES=(
  "$HOME/.claude:CLAUDE.md:skills"
  "$HOME/.codex:AGENTS.md:skills"
  "$HOME/.config/opencode:AGENTS.md:skill"
)

# Replace $2 with a symlink to $1, backing up any pre-existing real file/dir.
link() {
  local src="$1" dst="$2"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$dst" "$BACKUP_DIR/$(echo "${dst#"$HOME"/}" | tr / _)"
    echo "  backed up: $dst -> $BACKUP_DIR"
  fi
  ln -sfn "$src" "$dst"
  echo "  linked:    $dst -> $src"
}

for entry in "${HARNESSES[@]}"; do
  IFS=: read -r dir agents_name skills_name <<<"$entry"
  if [ ! -d "$dir" ]; then
    echo "skip: $dir (not installed)"
    continue
  fi
  echo "installing into $dir"
  link "$REPO/AGENTS.md" "$dir/$agents_name"
  mkdir -p "$dir/$skills_name"
  # prune symlinks to skills that were removed from the repo
  for existing in "$dir/$skills_name"/*; do
    if [ -L "$existing" ] && [[ "$(readlink "$existing")" == "$REPO"/skills/* ]] && [ ! -e "$existing" ]; then
      rm "$existing"
      echo "  pruned:    $existing"
    fi
  done
  for skill in "$REPO"/skills/*/; do
    link "${skill%/}" "$dir/$skills_name/$(basename "$skill")"
  done
done

# --- external modules (modules.yaml) ---
# Flat schema: "- repo:" starts an entry; "ref:" and "install:" are optional keys.
if [ -f "$REPO/modules.yaml" ]; then
  mkdir -p "$REPO/modules"
  while IFS=$'\037' read -r repo_url ref install_cmd; do
    [ -z "$repo_url" ] && continue
    name="$(basename "$repo_url" .git)"
    dest="$REPO/modules/$name"
    echo "module: $name"
    if [ -d "$dest/.git" ]; then
      git -C "$dest" fetch --quiet origin
    else
      git clone --quiet "$repo_url" "$dest"
    fi
    if [ -n "$ref" ]; then
      git -C "$dest" checkout --quiet "$ref"
      git -C "$dest" merge --quiet --ff-only "origin/$ref" 2>/dev/null || true
    else
      git -C "$dest" merge --quiet --ff-only "origin/HEAD" 2>/dev/null || true
    fi
    if [ -n "$install_cmd" ]; then
      (cd "$dest" && bash -c "$install_cmd")
    fi
  done < <(awk '
    function val(s) { sub(/^[^:]*:[[:space:]]*/, "", s); return s }
    /^[[:space:]]*-[[:space:]]*repo:/ { if (repo) print repo "\037" ref "\037" cmd; repo=val($0); ref=""; cmd="" }
    /^[[:space:]]+ref:/     { ref=val($0) }
    /^[[:space:]]+install:/ { cmd=val($0) }
    END { if (repo) print repo "\037" ref "\037" cmd }
  ' "$REPO/modules.yaml")
fi

echo "done."
