#!/usr/bin/env bash
# Symlink this repo as the build-loop skill. Idempotent.
set -euo pipefail

repo="$(cd "$(dirname "$0")" && pwd)"
dest="$HOME/.claude/skills/build-loop"

mkdir -p "$HOME/.claude/skills"

if [ -L "$dest" ]; then
  current="$(readlink "$dest")"
  if [ "$current" = "$repo" ]; then
    echo "Already linked: $dest -> $repo"
    exit 0
  fi
  echo "Replacing existing symlink ($current)"
  rm "$dest"
elif [ -e "$dest" ]; then
  echo "ERROR: $dest exists and is not a symlink. Move it aside first." >&2
  exit 1
fi

ln -s "$repo" "$dest"
echo "Linked: $dest -> $repo"
echo "Invoke with the build-loop skill in any project."
