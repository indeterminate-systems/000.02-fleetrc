# kiri-lite: the Kiri container engine (Docker Engine API) without its GTK window.
# On Linux it runs on the host kernel, no VM. Source: npins pin `kiri` (github.com/vic/kiri).
{ lib, rustPlatform, src }:
rustPlatform.buildRustPackage {
  pname = "kiri-lite";
  version = "0-unstable-${builtins.substring 0 7 (src.revision or "src")}";
  inherit src;
  cargoLock.lockFile = "${src}/Cargo.lock";
  cargoBuildFlags = [ "-p" "kiri" "-p" "kiri-init" ];
  doCheck = false;
  meta = {
    description = "Tiny, fast container runtime speaking the Docker Engine API (engine only)";
    homepage = "https://runkiri.com";
    license = lib.licenses.asl20;
    mainProgram = "kiri";
    platforms = lib.platforms.linux;
  };
}
