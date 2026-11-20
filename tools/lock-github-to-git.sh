#!/usr/bin/env bash
# Rewrite every github: node in a flake.lock to an equivalent git+https node (same rev, same narHash).
# Works around proxies that block GitHub's API/tarball endpoints but allow git clones.
set -euo pipefail
lock=${1:-flake.lock}
tmp=$(mktemp)
jq '.nodes |= with_entries(
  if .value.locked.type? == "github" then
    .value.locked = ({type:"git", url:"https://github.com/\(.value.locked.owner)/\(.value.locked.repo)",
                      rev:.value.locked.rev, narHash:.value.locked.narHash,
                      lastModified:.value.locked.lastModified, shallow:true})
    | .value.original = ({type:"git", url:"https://github.com/\(.value.original.owner)/\(.value.original.repo)", shallow:true}
        + (if .value.original.ref then {ref:.value.original.ref} else {} end)
        + (if .value.original.rev then {rev:.value.original.rev} else {} end))
  else . end)' "$lock" > "$tmp"
mv "$tmp" "$lock"
echo "rewrote $(jq '[.nodes[] | select(.locked.type? == "git")] | length' "$lock") nodes to git in $lock"
