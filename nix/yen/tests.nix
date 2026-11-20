# Each rule must fire on the mistake it exists for. A clean fleet alone proves nothing.
{
  yen,
  lib,
  fleet,
  runCommand,
}:
let
  verdictOf =
    f:
    (import ./check.nix {
      inherit yen lib runCommand;
      fleet = f;
    }).verdict;
  withEnv = name: env: lib.recursiveUpdate fleet { environments.${name} = env; };
  base = {
    managed = true;
    allowed_hosts = [ ];
    allow_package_managers = true;
    notes = "";
    id = "test";
  };
  cases = {
    clean = {
      got = verdictOf fleet;
      want = {
        ok = true;
        violations = [ ];
        incomplete = [ ];
        errors = [ ];
      };
    };
    # a Cloudflare token pasted into an environment whose role is `nix`
    secret-leak = {
      got = verdictOf (
        withEnv "leaky" (
          base
          // {
            role = "nix";
            network = "unrestricted";
            env_var_names = [
              "FLY_API_TOKEN"
              "CLOUDFLARE_API_TOKEN"
            ];
          }
        )
      );
      want = {
        ok = false;
        incomplete = [ ];
        errors = [ ];
        violations = [
          [
            "bad"
            "secret-not-in-role"
            "fleet:main/env:leaky"
            "fleet:main/secret:CLOUDFLARE_API_TOKEN"
          ]
        ];
      };
    };
    # a limited environment for typst-cloudflare that forgot the Cloudflare API host
    network-gap = {
      got = verdictOf (
        withEnv "tight" (
          base
          // {
            role = "typst-cloudflare";
            network = "limited";
            env_var_names = [ ];
            allowed_hosts = [
              "cache.nixos.org"
              "releases.nixos.org"
              "github.com"
            ];
          }
        )
      );
      want = {
        ok = false;
        incomplete = [ ];
        errors = [ ];
        violations = [
          [
            "bad"
            "network-misses-role-host"
            "fleet:main/env:tight"
            "fleet:main/nethost:api.cloudflare.com"
          ]
        ];
      };
    };
  };
  failed = lib.filterAttrs (_: c: c.got != c.want) cases;
in
if failed == { } then
  runCommand "fleetrc-yen-tests" { }
    "echo ${lib.escapeShellArg (toString (lib.attrNames cases))} passed > $out"
else
  throw "fleetrc: Yen rule tests failed:\n${
    builtins.toJSON (lib.mapAttrs (_: c: { inherit (c) got want; }) failed)
  }"
