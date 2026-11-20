# fleetrc entry point (no flakes). Pins live in ./npins (nixpkgs is a channel pin,
# git pins use --submodules so they are fetched with git, never as GitHub tarballs).
#
#   nix-build -A roles.<role>.profile      packages for a session, no init        (option 1)
#   nix-build -A roles.<role>.home         Home Manager activation package         (option 1)
#   nix-build -A roles.<role>.hjem         Hjem standalone config (lighter than HM) (option 1)
#   nix-build -A roles.<role>.nixos        NixOS container system (systemd)        (options 3, 4)
#   nix-build -A roles.<role>.oci          OCI image of that system, docker-loadable (option 4)
{
  sources ? import ./npins,
  system ? builtins.currentSystem,
}:
let
  pkgs = import sources.nixpkgs { inherit system; };
  inherit (pkgs) lib;
  roleDefs = import ./roles { inherit pkgs; };
  hjemCli = pkgs.callPackage "${sources.hjem}/cli/package.nix" { };

  mkRole =
    name: def:
    let
      packages = def.packages or [ ];

      profile = pkgs.buildEnv {
        name = "fleetrc-${name}";
        paths = packages;
        pathsToLink = [ "/bin" "/share" "/etc" "/lib" ];
        ignoreCollisions = true;
      };

      home =
        (import "${sources.home-manager}/modules" {
          inherit pkgs;
          configuration = {
            home.username = "root";
            home.homeDirectory = "/root";
            home.stateVersion = "25.11";
            home.packages = packages;
            imports = [ (def.home or { }) ];
          };
        }).activationPackage;

      # Hjem standalone: `hjem standalone switch --config <this file>` links files and
      # installs packages into ~/.local/state/hjem/standalone/current-profile.
      hjem = pkgs.writeText "fleetrc-${name}-hjem.nix" ''
        let fleet = import ${toString ./.} { };
        in {
          manifest = { version = 3; files = fleet.roles.${name}.hjemFiles; };
          packages = fleet.roles.${name}.packages;
        }
      '';
      hjemFiles = def.hjemFiles or [ ];

      nixosEval = import "${sources.nixpkgs}/nixos/lib/eval-config.nix" {
        inherit system;
        modules = [
          ./nixos/container.nix
          { networking.hostName = "fleetrc-${name}"; environment.systemPackages = packages; }
          (def.nixos or { })
        ];
      };
      nixos = nixosEval.config.system.build.toplevel;

      oci = import ./nixos/oci.nix { inherit pkgs name nixos; };
    in
    {
      inherit
        name
        packages
        profile
        home
        hjem
        hjemFiles
        nixos
        oci
        ;
    };
in
{
  inherit pkgs sources hjemCli;
  roles = lib.mapAttrs mkRole roleDefs;
}
