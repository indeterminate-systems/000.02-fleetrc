# OCI image that boots a NixOS container system with systemd as PID 1.
# The entrypoint swaps the runtime's cgroup v1 mounts for cgroup2 first,
# because current systemd refuses to start on cgroup v1.
{ pkgs, name, nixos }:
let
  boot = pkgs.writeScript "fleetrc-boot" ''
    #!${pkgs.runtimeShell}
    export PATH=${pkgs.coreutils}/bin:${pkgs.util-linux}/bin:${pkgs.gawk}/bin:${pkgs.gnugrep}/bin
    if ! grep -q ' /sys/fs/cgroup cgroup2 ' /proc/mounts; then
      for m in $(grep ' /sys/fs/cgroup/' /proc/mounts | awk '{print $2}' | sort -r); do umount "$m" || true; done
      umount /sys/fs/cgroup 2>/dev/null || true
      mount -t cgroup2 cgroup2 /sys/fs/cgroup
    fi
    exec ${nixos}/init
  '';
in
pkgs.dockerTools.streamLayeredImage {
  name = "fleetrc-${name}";
  tag = "latest";
  contents = [ ];
  extraCommands = "mkdir -p etc tmp run var root";
  config = {
    Entrypoint = [ boot ];
    Env = [ "container=docker" ];
    Labels."org.opencontainers.image.source" = "https://github.com/indeterminate-systems/000.02-fleetrc";
  };
  maxLayers = 100;
}
