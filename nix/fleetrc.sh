# shellcheck shell=bash
# fleetrc: apply a role to this box, or report what it has.
#   fleetrc apply <role>   build role.<role> from $FLEETRC_SRC (default: cwd) and install it
#   fleetrc status         show the applied role, its tools and which of its secrets are set
profile=/nix/var/nix/profiles/fleetrc
state=/etc/fleetrc
src=${FLEETRC_SRC:-$PWD}

die() { echo "fleetrc: $*" >&2; exit 1; }

apply() {
  local role=$1 out
  [ -f "$src/default.nix" ] || die "no fleetrc checkout at $src (set FLEETRC_SRC)"
  out=$(nix-build --no-out-link "$src" -A "role.$role") || die "unknown or broken role: $role"
  nix-env -p "$profile" --set "$out" >/dev/null
  mkdir -p "$state" /etc/profile.d
  echo "$role" > "$state/role"
  nix-instantiate --eval --json --strict "$src" -A "role.$role.spec" > "$state/spec.json"
  # shellcheck disable=SC2016 # $PATH must expand at login, not now
  printf 'export PATH=%s/bin:$PATH\n' "$profile" > /etc/profile.d/fleetrc.sh
  # Claude's shell snapshot comes from /etc/bash.bashrc. Hook in at the top, like the Nix installer,
  # so non-interactive shells (which return early further down) get the profile too.
  if ! grep -qs 'profile.d/fleetrc.sh' /etc/bash.bashrc; then
    { echo '[ -e /etc/profile.d/fleetrc.sh ] && . /etc/profile.d/fleetrc.sh # fleetrc'
      cat /etc/bash.bashrc 2>/dev/null; } > /etc/bash.bashrc.fleetrc
    mv /etc/bash.bashrc.fleetrc /etc/bash.bashrc
  fi
  echo "fleetrc: role $role applied ($out)"
}

status() {
  [ -f "$state/role" ] || die "no role applied"
  echo "role: $(cat "$state/role")"
  echo "tools: $(jq -r '.tools | join(" ")' "$state/spec.json")"
  local s
  for s in $(jq -r '.secrets[]' "$state/spec.json"); do
    if [ -n "${!s:-}" ]; then echo "secret $s: set"; else echo "secret $s: MISSING"; fi
  done
}

case "${1:-}" in
  apply) [ $# -eq 2 ] || die "usage: fleetrc apply <role>"; apply "$2" ;;
  status) status ;;
  *) die "usage: fleetrc apply <role> | fleetrc status" ;;
esac
