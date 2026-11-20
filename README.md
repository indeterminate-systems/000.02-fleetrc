# fleetrc

One checked fleet for all Claude cloud environments: each environment gets a role, and its setup script bootstraps that role from this repo.

## Use a role in a session

    git clone https://github.com/indeterminate-systems/000.02-fleetrc /opt/fleetrc
    /opt/fleetrc/bin/rc <role> [mode]

Roles are defined in [roles/default.nix](roles/default.nix): `base` and `nix`.

| mode | what you get | systemd services | time in a fresh session* |
|---|---|---|---|
| `profile` (default) | role packages on PATH via the default Nix profile | no | ~3 s |
| `hjem` | [Hjem](https://hjem.feel-co.org/) standalone: packages + managed files, generations | no | seconds |
| `home` | Home Manager generation (build only; run its `activate`) | no | seconds |
| `nspawn` | the role's NixOS booted with systemd-nspawn, no Docker | yes | ~17 s |
| `docker` | the role's NixOS from its OCI image (pulled from ghcr.io, else built) | yes | ~60 s built locally |

\* Measured 2026-11-19 with a warm local store. Without the cache, the first build adds download time.

**Cache:** `rc` uses `https://$FLEETRC_CACHE.cachix.org` (default `fleets`) automatically once it exists.
CI ([.github/workflows/build.yml](.github/workflows/build.yml)) builds every role and pushes store paths
to Cachix (needs the `CACHIX_AUTH_TOKEN` secret) and OCI images to `ghcr.io/<owner>/fleetrc-<role>`.

**Pins:** [npins](npins/sources.json). nixpkgs is a channel pin. Git pins are added with `--submodules` so npins
fetches them with git, because cloud sessions block GitHub tarball downloads.

- [docs/kickoff.md](docs/kickoff.md): goal, terms, proposed stack, constraints, first steps
- [docs/nix-portable-inventory.md](docs/nix-portable-inventory.md): what a cloud session actually has
- [recipes/nixos-in-docker](recipes/nixos-in-docker): real NixOS (systemd PID 1) inside a session
- [recipes/dungeon-git](recipes/dungeon-git): vic/dungeon over git, with the GitHub-tarball shim
- [tools/lock-github-to-git.sh](tools/lock-github-to-git.sh): rewrite flake.lock github nodes to git

## Experimental: kiri-lite

`nix-build -A kiri` builds [kiri](https://github.com/vic/kiri)'s engine (no GTK window) from source, about 3 minutes uncached.
In a session (2026-11-19) `kiri daemon` answered the Docker API in about 0.1 s using about 6 MB RAM, where dockerd takes several seconds.
Running containers failed, though (`guest stopped before connecting: the agent exited: exit status: 1`), and the session's VM
died twice while booting the NixOS image with it. So kiri is **not** wired into `bin/rc`. Debug it on a real Linux machine first.
