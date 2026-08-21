#!/usr/bin/env bash

# Increase the open file limit to prevent "Too many open files" errors
ulimit -n 65536

if [[ "$1" == "--update-all" ]]; then
    nix flake update
elif [[ "$1" == "--update-latest" ]]; then
    nix flake update nixpkgs-latest
    nix flake update quickshell
    nix flake update zen-browser
    nix flake update zig-overlay
fi

sudo nixos-rebuild switch --flake .#nixos
