# fleetrc

One checked fleet for all Claude cloud environments: each environment gets a role, and its setup script bootstraps that role from this repo.

- [docs/kickoff.md](docs/kickoff.md): goal, terms, proposed stack, constraints, first steps
- [docs/nix-portable-inventory.md](docs/nix-portable-inventory.md): what a cloud session actually has
- [recipes/nixos-in-docker](recipes/nixos-in-docker): real NixOS (systemd PID 1) inside a session
- [recipes/dungeon-git](recipes/dungeon-git): vic/dungeon over git, with the GitHub-tarball shim
- [tools/lock-github-to-git.sh](tools/lock-github-to-git.sh): rewrite flake.lock github nodes to git
