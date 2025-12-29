#!/usr/bin/env bash
set -euo pipefail

run_install() {
  local root_dir="$1"
  shift || true
  local tags=("$@")

  ensure_ubuntu

  export OS_UBUNTU_ROOT="$root_dir"
  export OS_UBUNTU_STATE_DIR="$root_dir/state"

  log "Running always-on scripts: req/"
  run_folder "$root_dir/req" "req" || die "Failed in req/"

  log "Running always-on scripts: pre/"
  run_folder "$root_dir/pre" "pre" || die "Failed in pre/"

  if [[ ${#tags[@]} -eq 0 ]]; then
    log "No tags specified; nothing else to run."
    return 0
  fi

  local tag
  for tag in "${tags[@]}"; do
    if [[ ! -d "$root_dir/$tag" ]]; then
      die "Unknown tag folder: $tag (missing directory: $root_dir/$tag)"
    fi
    log "Running tag folder: $tag/"
    run_folder "$root_dir/$tag" "$tag" || die "Failed in tag: $tag/"
  done
}

run_folder() {
  local folder="$1"
  local tag="$2"

  [[ -d "$folder" ]] || return 0

  local files=()
  # compgen returns non-zero when no matches; swallow it.
  while IFS= read -r f; do
    files+=("$f")
  done < <(compgen -G "$folder/*.sh" 2>/dev/null | sort || true)

  if [[ ${#files[@]} -eq 0 ]]; then
    log "No scripts found in $tag/ (folder: $folder)"
    return 0
  fi

  local f
  for f in "${files[@]}"; do
    log "Running: $tag/$(basename "$f")"
    OS_UBUNTU_TAG="$tag" bash "$f"
  done
}

