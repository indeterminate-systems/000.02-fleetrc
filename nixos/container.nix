# NixOS as a container inside a Claude cloud session (no kexec, host cgroups are v1,
# host networking, /etc/hosts and /etc/hostname managed by the runtime).
{ lib, ... }:
{
  boot.isContainer = true;
  networking.useHostResolvConf = lib.mkForce false;
  networking.useDHCP = false;
  networking.firewall.enable = false;
  services.getty.autologinUser = "root";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "25.11";
}
