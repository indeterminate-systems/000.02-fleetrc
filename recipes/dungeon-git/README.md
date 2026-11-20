# Using vic/dungeon in a Claude cloud session

Tested 2026-11-19: Den's `minimal` template with `den` replaced by dungeon evaluates and builds
(`nixosConfigurations.igloo` toplevel built in ~23 s, mostly cache downloads).

## Why it needs a shim
The session proxy blocks GitHub's API and tarball URLs for repos not attached to the session, but
allows plain git reads of public repos. dungeon depends on gen (sini/gen), and gen plus each of its
~24 sub-libraries fetch their own pins with `builtins.fetchTree`/`fetchTarball` on `github:` nodes.
Those calls happen inside library code, so flake-input overrides and `follows` can't reach them.

## What the shim does
- `dungeon-git/flake.nix`: fetches dungeon and gen with `git+https`, then imports them through
  `github-as-git.nix`.
- `github-as-git.nix`: imports a file with `builtins.scopedImport`, swapping in versions of
  `fetchTree`/`fetchTarball` that fetch GitHub revs over git instead. The swap carries through
  every nested `import`. Same rev and narHash, so the store paths are identical to the tarball ones.
- `den-minimal/`: Den's minimal template with `den.url = "path:../dungeon-git"`.

## Use
    cd den-minimal
    nix build .#nixosConfigurations.igloo.config.system.build.toplevel

In your own flake, set `inputs.den.url` to the dungeon-git flake (local path, or push it to a repo
of yours and use `git+https://...`). Any other `github:` inputs: use `git+https://...?shallow=1`, or run
`../../tools/lock-github-to-git.sh flake.lock` after locking.

Off-session (on a normal machine) none of this is needed: use `github:vic/dungeon` directly.
