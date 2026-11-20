# Each role: { packages = [ ... ]; home = <HM module>; nixos = <NixOS module>; }
# home and nixos are optional.
{ pkgs }:
let
  base = with pkgs; [
    git
    jq
    ripgrep
    fd
    curl
    htop
    npins
    nixfmt
  ];
in
{
  base = {
    packages = base;
  };

  nix = {
    packages = base ++ (with pkgs; [ nickel nls nix-output-monitor cachix ]);
    nixos = {
      services.openssh.enable = true;
    };
  };

  typst-cloudflare = {
    packages = base ++ (with pkgs; [ typst wrangler nodejs_22 ]);
  };
}
