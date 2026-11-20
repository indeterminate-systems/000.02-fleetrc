# fleetrc, flake-less. Pins live in npins/sources.json.
#   nix-build -A role.<name>   the role's tool profile
#   nix-build -A rc            the `fleetrc` command the setup scripts run
#   nix-build -A check         Yen fleet rules (fails on any violation)
#   nix-build -A tests         each Yen rule fires on the mistake it exists for
#   nix-shell -A shell         Nickel, npins, jq for editing the fleet
{
  sources ? import ./npins,
  pkgs ? import sources.nixpkgs { },
}:
let
  inherit (pkgs) lib;
  fleet = lib.importJSON ./generated/fleet.json;

  role = lib.mapAttrs (
    name: r:
    pkgs.buildEnv {
      name = "fleetrc-role-${name}";
      paths = [ rc ] ++ map (attr: lib.getAttrFromPath (lib.splitString "." attr) pkgs) r.tools;
      passthru.spec = r;
    }
  ) fleet.roles;

  yen = pkgs.callPackage ./nix/yen/check.nix {
    yen = sources.yen;
    inherit fleet;
  };

  rc = pkgs.writeShellApplication {
    name = "fleetrc";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = builtins.readFile ./nix/fleetrc.sh;
  };
in
{
  inherit role rc fleet;
  check = yen.drv;
  tests = pkgs.callPackage ./nix/yen/tests.nix {
    yen = sources.yen;
    inherit fleet;
  };
  yenVerdict = yen.verdict;
  shell = pkgs.mkShell {
    packages = [
      pkgs.nickel
      pkgs.npins
      pkgs.jq
      pkgs.nixfmt
      pkgs.shellcheck
    ];
  };
}
