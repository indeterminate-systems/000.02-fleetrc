# fleetrc

All Claude cloud environments, managed as one checked fleet. Each environment gets a **role**. Its setup
script is a small generated bootstrap that builds that role from this repo.

| Term | Meaning |
|---|---|
| Environment | the saved claude.ai config (network, env var names, setup script). Deploying here needs the user's approval. |
| Role | what fleetrc defines: tools, the secrets it may receive, the hosts it needs. One role can serve several environments. |
| Session | a temporary container started from an environment. It re-applies the role every time it starts. |

## Layout

```
fleet/schema.ncl         Nickel contracts: Role, Environment
fleet/roles.ncl          roles: nix, typst-cloudflare
fleet/environments.ncl   inventory of all 5 environments (2 managed, 3 inventory-only)
fleet/main.ncl           checks role references, generates every file below
generated/fleet.json     data that Nix and Yen read
generated/setup/*.sh     setup script for each managed environment
.github/workflows/       CI (generated too)
default.nix              flake-less entry: role.<name>, rc, check, tests, shell
nix/fleetrc.sh           the `fleetrc apply|status` command
nix/yen/                 Yen model (built from fleet.json), rules, rule tests
npins/                   nixpkgs (channel pin) and yen (git pin, --forge none)
```

## Workflow

```bash
nix-shell -A shell                  # nickel, npins, jq, nixfmt, shellcheck
$EDITOR fleet/roles.ncl
./generate                          # nickel export → generated/, CI
nix-build -A check -A tests         # Yen rules hold; each rule fires on its mistake
nix-build -A role.nix               # build a role
```

`./generate --check` fails when a committed generated file has drifted from `fleet/*.ncl`. CI runs it.

## Yen rules (`nix/yen/rules.nix`)

- **secret-not-in-role**: an environment holds a secret only if its role names it.
- **network-misses-role-host**: on a `limited` network, every host the role needs is allowed.

Inventory-only environments (`managed = false`) aren't checked until they get a role.

## Bootstrap

Each generated setup script uses the session's checkout of this repo (`./000.02-fleetrc`, cloned
before setup runs). If there isn't one, it tries `git clone` into `/opt/fleetrc`. Then it runs
`nix-build -A rc` and `fleetrc apply <role>`, which:

- installs the role into `/nix/var/nix/profiles/fleetrc`
- puts that profile on PATH by hooking `/etc/profile.d/fleetrc.sh` into the top of `/etc/bash.bashrc`
- records the role in `/etc/fleetrc`

The script **never fails the session**. On any problem it warns and exits 0. Setup scripts can't
read secrets: `fleetrc status` checks at session time that the role's secrets are set.

## Findings (tested 2026-11-20, Nix-Portable)

- Nickel 1.18.0 and npins 0.5.1 come from the nixpkgs channel cache.
- `npins add git` on a github.com URL still auto-detects GitHub and fetches an archive tarball, which returns
  403. Pass `--forge none`.
- Yen (`vic/yen`) is builtins-only, so it evaluates flake-less from the git pin. Use `lib.eval`, not
  `mkFlake`, and don't pass `lib` unless a module reads it (`unread-sink` error).
- In Nickel, record fields are recursive: `{ repo = repo }` is infinite recursion. Give `let` bindings
  names that differ from the fields.
- organist is skipped. Its last real commit was 2024-10, and `nix-shell -A shell` covers the dev shell.
- The repo is **private**, so a fresh `git clone` from a setup script only works when the session
  already has the repo attached. To make every environment self-bootstrapping, either attach the repo to
  the sessions or make it public.
