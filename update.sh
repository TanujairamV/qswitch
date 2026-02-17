#!/usr/bin/env bash
set -uo pipefail

# ───── UI helpers ─────
info() { echo -e "\n󰉋 \e[1;34m$1\e[0m"; }
ok()   { echo -e "  ✔ \e[1;32mDone\e[0m"; }
warn() { echo -e "  ⚠ \e[1;33m$1\e[0m"; }
err()  { echo -e "  ✖ \e[1;31m$1\e[0m"; }

# ───── Error tracking ─────
ERROR=0
trap 'ERROR=1' ERR

pause_if_needed() {
  if (( ERROR )); then
    echo -e "\n⚠ Errors occurred. Press Enter to exit..."
    read
  fi
}

# ───── Core logic ─────
update_repo() {
  local dir="$1"
  local git_cmd="git"

  [[ -d "$dir/.git" ]] || { warn "Skipping $dir (not a git repo)"; return 0; }

  info "Updating $dir"

  if ! pushd "$dir" >/dev/null 2>&1; then
    err "Cannot enter $dir"
    return 0
  fi

  # Root-owned repo → use sudo
  if [[ ! -w ".git" ]]; then
    git_cmd="sudo git"
  fi

  # Never touch dirty repos
  if [[ -n "$($git_cmd status --porcelain 2>/dev/null)" ]]; then
    warn "Uncommitted changes — skipping pull"
    popd >/dev/null
    return 0
  fi

  local before after
  before="$($git_cmd rev-parse HEAD)"

  if ! $git_cmd pull --rebase --ff-only; then
    err "Git pull failed"
    popd >/dev/null
    return 0
  fi

  after="$($git_cmd rev-parse HEAD)"

  popd >/dev/null
  ok
}

# ───── Repositories ─────
REPOS=(
  "$HOME/.cache/dots-hyprland"
  "$HOME/qswitch"
  "$HOME/Ambxst"
  "/etc/xdg/quickshell/noctalia-shell"
  "/etc/xdg/quickshell/xenon"
  "/etc/xdg/quickshell/Ambxst"
  "/etc/xdg/quickshell/nucleus-shell"
)

for repo in "${REPOS[@]}"; do
  update_repo "$repo"
done

info "All repos processed 🚀"
pause_if_needed
