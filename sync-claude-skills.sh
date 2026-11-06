#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: sync-claude-skills.sh [--dry-run] [DESTINATION]

Create symlinks in Claude's skills directory for every immediate subdirectory
next to this script that contains a SKILL.md file.

DESTINATION defaults to $CLAUDE_SKILLS_DIR, or $HOME/.claude/skills when that
variable is unset. Existing files and links not managed by this script are
left untouched. Stale links pointing directly into this repository are removed.
EOF
}

dry_run=false
destination=""

while (($#)); do
  case "$1" in
    --dry-run|-n)
      dry_run=true
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      if (($# > 1)); then
        echo "error: expected at most one destination" >&2
        usage >&2
        exit 2
      fi
      destination="${1:-}"
      break
      ;;
    -*)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -n "$destination" ]]; then
        echo "error: expected at most one destination" >&2
        usage >&2
        exit 2
      fi
      destination="$1"
      ;;
  esac
  shift
done

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

if [[ -z "$destination" ]]; then
  if [[ -n "${CLAUDE_SKILLS_DIR:-}" ]]; then
    destination="$CLAUDE_SKILLS_DIR"
  elif [[ -n "${HOME:-}" ]]; then
    destination="$HOME/.claude/skills"
  else
    echo "error: HOME is unset; pass the destination directory explicitly" >&2
    exit 2
  fi
fi

if [[ "$destination" != /* ]]; then
  destination="$PWD/$destination"
fi

run() {
  if $dry_run; then
    printf 'would run:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

if [[ -e "$destination" && ! -d "$destination" ]]; then
  echo "error: destination exists but is not a directory: $destination" >&2
  exit 1
fi

run mkdir -p "$destination"

conflicts=0
linked=0
unchanged=0
removed=0

shopt -s nullglob
for skill_file in "$script_dir"/*/SKILL.md; do
  skill_dir="${skill_file%/SKILL.md}"
  skill_name="${skill_dir##*/}"
  target="$destination/$skill_name"
  if [[ -L "$target" ]]; then
    current_target="$(readlink "$target")"
    if [[ "$current_target" == "$skill_dir" ]]; then
      ((unchanged += 1))
      continue
    fi

    echo "conflict: $target already links to $current_target" >&2
    ((conflicts += 1))
    continue
  fi

  if [[ -e "$target" ]]; then
    echo "conflict: $target already exists and was not changed" >&2
    ((conflicts += 1))
    continue
  fi

  run ln -s "$skill_dir" "$target"
  ((linked += 1))
done

# Remove only stale links created in the same absolute form as the links above.
# Files, directories, relative links, and links to any other source are preserved.
if [[ -d "$destination" ]]; then
  for target in "$destination"/*; do
    [[ -L "$target" ]] || continue
    skill_name="${target##*/}"
    [[ ! -f "$script_dir/$skill_name/SKILL.md" ]] || continue

    current_target="$(readlink "$target")"
    if [[ "$current_target" == "$script_dir"/* && "${current_target%/*}" == "$script_dir" ]]; then
      run rm "$target"
      ((removed += 1))
    fi
  done
fi

if $dry_run; then
  action="planned"
else
  action="complete"
fi

printf 'Sync %s: %d linked, %d unchanged, %d stale removed, %d conflicts\n' \
  "$action" "$linked" "$unchanged" "$removed" "$conflicts"

((conflicts == 0))
