#!/usr/bin/env bash
# Boot real NixOS (systemd as PID 1) inside Docker in a Claude Code cloud container.
# Tested 2026-11-19 in the Nix-Portable environment. Run as root from this folder.
set -euo pipefail
W=/root/nixos-ct; mkdir -p $W; cp flake.nix $W/; cd $W
# 1. Docker daemon is not running at session start; detach it so it survives the shell.
docker info >/dev/null 2>&1 || { setsid nohup dockerd >/tmp/dockerd.log 2>&1 </dev/null & sleep 8; }
# 2. Build the NixOS system (nixpkgs comes from channels.nixos.org; github.com API is blocked here).
nix build .#nixosConfigurations.ct.config.system.build.toplevel
SYS=$(readlink -f result)
# 3. Empty root fs; /nix is bind-mounted from the host. boot.sh swaps Docker's cgroup v1
#    mounts for a cgroup2 mount, because current systemd refuses to boot on cgroup v1.
mkdir -p rootfs/{nix,dev,proc,sys,run,tmp,etc}
cat > rootfs/boot.sh <<EOS
#!$SYS/sw/bin/bash
export PATH=$SYS/sw/bin
for m in \$(grep ' /sys/fs/cgroup/' /proc/mounts | awk '{print \$2}'); do umount \$m; done
umount /sys/fs/cgroup 2>/dev/null || true
mount -t cgroup2 cgroup2 /sys/fs/cgroup
exec $SYS/init
EOS
chmod +x rootfs/boot.sh
(cd rootfs && tar -c . | docker import - nixos-empty:latest >/dev/null)
docker rm -f nixos1 >/dev/null 2>&1 || true
docker run -d --name nixos1 --privileged --network host --cgroupns=private \
  -v /nix:/nix -e container=docker nixos-empty:latest /boot.sh
sleep 15
docker exec nixos1 /run/current-system/sw/bin/systemctl is-system-running || true
echo "Shell in:  docker exec -it nixos1 /run/current-system/sw/bin/bash -l"
echo "Live switch after editing flake.nix:  nix build ...toplevel -o result2 && docker exec nixos1 \$(readlink -f result2)/bin/switch-to-configuration switch"
