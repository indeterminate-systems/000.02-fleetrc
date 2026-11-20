# Nix-Portable cloud environment: inventory

Captured 2026-11-19 from inside a session running in it (read-only, nothing changed).

## User-provided settings (what's actually configured on the environment)

| Setting | Value |
|---|---|
| Name | Nix-Portable (`env_01Hhrb1WTHn2DAKpFRkn652i`) |
| Scope | Personal |
| Description | (empty) |
| Network access | **Unrestricted** (no allowlist) |
| Environment variables | `FLY_API_TOKEN` (set; value not shown) |
| Network secrets | none |
| Repositories | none attached |
| Setup script | Present, but **every line is a comment**, so it does nothing. |

The setup script's full text is a commented-out list of hosts, which looks like an allowlist someone drafted and then left in the script box:

```
# huggingface.co
# *.huggingface.co
# *.hf.co
# registry.ollama.ai
# ollama.com
# github.com
# api.github.com
# objects.githubusercontent.com
# typesafe.ai
# docs.typesafe.ai
```

Because the network is unrestricted, those hosts are reachable anyway (checked: huggingface.co 200, ollama.com 200, cache.nixos.org 200, api.fly.io reachable).

## Nix (not installed by the current setup script; origin unverified: base image or a leftover from an earlier script)

- Nix 2.34.6, installed 2026-11-16 by the official NixOS `nix-installer` (receipt at `/nix/receipt.json`). This is the standard multi-user Nix, **not nix-portable**: no `nix-portable` binary or `~/.nix-portable` exists.
- `/etc/nix/nix.conf`: flakes + nix-command enabled, `auto-optimise-store`, `always-allow-substitutes`, `max-jobs = auto`, `nixpkgs=flake:nixpkgs` on the nix path; includes `nix.custom.conf` (only sets `ssl-cert-file`).
- Substituter: `https://cache.nixos.org/` only. Sandbox on. Trusted user: root.
- Default profile contains only `nix` and `nss-cacert`. No channels, no user packages. Store is about 111 MB.
- No nix-daemon running (container has no systemd). `/etc/bash.bashrc` sources the nix-daemon profile script.

## Base container (same for every cloud environment)

- Ubuntu 24.04.5 LTS, x86_64, 4 vCPU, 15 GiB RAM, no swap, ~60 GB free disk.
- Runs as root, bash.
- Preinstalled toolchains on PATH: Node 22, Go, Rust/cargo, Bun, Ruby (rbenv), Java + Maven + Gradle, Python, gh, Playwright Chromium.
- Many other env vars exist (proxy, CA bundle, Claude Code, Git, cloud SDK), but those are injected by the platform, not set by the user.

## Docker (tested 2026-11-19)

- Docker 29.10.0 (client, dockerd, containerd, runc, buildx, compose) is installed, but the daemon is **not running** when a session starts. `setsid nohup dockerd &` starts it in a few seconds (overlayfs, cgroupfs, cgroup v1).
- Docker Hub pulls failed with **429 Too Many Requests** (shared rate limit). GHCR works: `docker pull ghcr.io/nixos/nix:latest` (Nix 2.36.0).
- Containers need the proxy and CA passed in to reach the internet. This works:
  `docker run --rm --network host -v /root/.ccr/ca-bundle.crt:/ca.crt:ro -e NIX_SSL_CERT_FILE=/ca.crt -e HTTPS_PROXY="$HTTPS_PROXY" ghcr.io/nixos/nix nix run nixpkgs#hello` (output: Hello, world!)
- Full NixOS with systemd as PID 1: see next section (works).

## Real NixOS inside Docker (tested 2026-11-19)

Works. A NixOS 26.11 system built here with Nix boots with **systemd as PID 1** in a privileged container, reaches `running`, and takes live `switch-to-configuration switch` updates. Recipe: `recipes/nixos-in-docker/`.

Things that had to be worked around:
- dockerd must be started with `setsid` or it dies when the shell exits.
- github.com API is blocked for flake inputs, so nixpkgs comes from `https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz`.
- Host cgroups are v1 and current systemd won't boot on v1, so the entry script mounts cgroup2 before exec'ing NixOS init (cgroup2 has no controllers here, so no resource limits).
- `/etc/hosts` and `/etc/hostname` stay Docker-managed; dhcpcd fails with host networking, so `networking.useDHCP = false`.

Not possible here:
- **nixos-anywhere:** needs kexec, and this kernel is built without `CONFIG_KEXEC`.
- **nix-infect:** the VM is Firecracker with the kernel and init (`rdinit=/process_api`) supplied from outside, and reboot ends the VM. Infecting would wreck the session and never boot NixOS, so it was not run.

## GitHub flake inputs

`github:owner/repo` inputs fail here: the session proxy returns 403 for api.github.com, github.com/.../archive and codeload.github.com on repos not attached to the session. Plain git works, so use `git+https://github.com/owner/repo?ref=<branch>&shallow=1`, and add `inputs.<x>.inputs.nixpkgs.follows = "nixpkgs"` so transitive `github:` inputs don't get fetched. For nixpkgs itself, `https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz` is faster than a git clone.
