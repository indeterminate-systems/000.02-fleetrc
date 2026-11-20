{
  inputs.nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
  outputs = { nixpkgs, ... }: {
    nixosConfigurations.ct = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ({ pkgs, ... }: {
        boot.isContainer = true;
        networking.hostName = "nixos-in-ccr";
        networking.useHostResolvConf = false;
        services.getty.autologinUser = "root";
        users.users.root.initialPassword = "nixos";
        environment.systemPackages = [ pkgs.hello pkgs.htop ];
        nix.settings.experimental-features = [ "nix-command" "flakes" ];
        networking.useDHCP = false;
        services.openssh.enable = true;
        system.stateVersion = "25.11";
      }) ];
    };
  };
}
