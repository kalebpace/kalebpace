# container vm setup: CURRENTLY BROKEN
limactl start
podman system connection add lima-podman "unix:///Users/kaleb/.lima/podman/sock/podman.sock"
podman system connection default lima-podman

build nix derivation and run
nix-build && zcat result | podman load | sed -e 's/Loaded image\:\s//' | xargs -I{} podman run {}