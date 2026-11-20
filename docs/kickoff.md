# fleetrc: kickoff brief

**Goal:** manage all Claude cloud environments (Nix-Portable, xD-dev, xdgprobe, typst+Cloudflare, Default) as one checked fleet. Each environment gets a role. Its setup script is a tiny bootstrap that builds that role from this repo.

## Terms
- **Environment:** the saved claude.ai config (network, env var names, setup script). Fleet output is "deployed" here, and each change needs the user's approval.
- **Role:** what fleetrc defines: tools, secrets, NixOS system. One role can serve several environments.
- **Session:** a live, temporary container started from an environment. It rebuilds the role every time.

## Proposed stack (test before relying on any of it)
- **Nickel:** source of truth for roles and environments (typed contracts). Exports JSON for the others, plus generated environment settings, setup scripts and CI.
- **Nix + npins:** builds the role systems. Use flake-less `default.nix` with `npins/sources.json`.
- **Yen:** rules across the fleet (secrets only where named, network matches role, no drift between environments sharing a role).
- **organist:** optional, only for the repo's own dev shell. Check how actively it's maintained first.

## Bootstrap (every environment's setup script)
```
git clone https://github.com/indeterminate-systems/000.02-fleetrc /opt/fleetrc
cd /opt/fleetrc && nix run .#rc -- <role>   # or nix-build -A role.<role>
```
The setup script can't read the environment's secrets. Secrets come in at session time.

## Hard-won constraints (tested 2026-11-19, Nix-Portable)
- Base box: Ubuntu 24.04, root, 4 vCPU / 15 GiB, Firecracker VM. Nix 2.34.6 is preinstalled (flakes on). No systemd on the host.
- **GitHub:** tarball and API URLs return 403 for repos not attached to the session; plain git reads work. Use `git+https://...?shallow=1` flake inputs, or `npins add git ...` (never a `github` pin). The `nixpkgs` shortcut resolves through GitHub too, so take nixpkgs from a channel pin (`https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz`).
- **Libraries that fetch GitHub tarballs in their own code** (sini/gen, which dungeon and Den are built on) need the `github-as-git.nix` scopedImport shim. Don't try intercepting proxy traffic: policy refuses it.
- **Docker:** installed but not running. Start it with `setsid nohup dockerd &`. Docker Hub returns 429; use ghcr.io. Containers need `--network host` plus the session's CA bundle and HTTPS_PROXY.
- **Real NixOS:** boots with systemd as PID 1 in a privileged container. Mount cgroup2 first (host is cgroup v1), and set `networking.useDHCP = false`. Live `switch-to-configuration switch` works.
- **Not possible here:** nixos-anywhere (kernel has no kexec) and nix-infect (Firecracker supplies the kernel and init).

## Reference files (in this repo)
- `docs/nix-portable-inventory.md`: full environment inventory
- `recipes/nixos-in-docker/`: NixOS-in-Docker recipe (`run.sh`, `flake.nix`)
- `recipes/dungeon-git/`: dungeon via git with the shim, plus the Den minimal template
- `tools/lock-github-to-git.sh`: rewrites a lock file's github nodes to git

## First steps
1. Repo: `indeterminate-systems/000.02-fleetrc` (exists). Also see `indeterminate-systems/nix-dev-environment-templates`.
2. Smoke-test Nickel, npins (git pin), and organist in a session.
3. Define two roles: `nix` (Nix-Portable) and `typst-cloudflare`. Add a bootstrap and 2 Yen rules.
4. Generate a setup script for one environment and apply it, with approval.
