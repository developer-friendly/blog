#!/bin/bash
set -eux

export DEBIAN_FRONTEND=noninteractive
apt update
apt install -y squashfs-tools

# ref: https://gist.github.com/chris-martin/4ead9b0acbd2e3ce084576ee06961000
wget https://channels.nixos.org/nixos-${nixos_version}/latest-nixos-minimal-$(uname -m)-linux.iso -O nixos.iso

mkdir nixos
mount -o loop nixos.iso nixos

mkdir /nix
unsquashfs -d /nix/store nixos/nix-store.squashfs

NIXOS_INSTALL=$(find /nix/store -path '*-nixos-install/bin/nixos-install')
NIX_INSTANTIATE=$(find /nix/store -path '*-nix-*/bin/nix-instantiate')
NIXOS_GENERATE_CONFIG=$(find /nix/store -path '*-nixos-generate-config/bin/nixos-generate-config')
export PATH="$(dirname $NIXOS_INSTALL):$(dirname $NIX_INSTANTIATE):$(dirname $NIXOS_GENERATE_CONFIG):$PATH"

groupadd --system nixbld
useradd --system --home-dir /var/empty --shell $(which nologin) -g nixbld -G nixbld nixbld0

wget https://github.com/NixOS/nixpkgs/archive/refs/tags/${nixpkgs_version}.zip -O nixpkgs.zip
unzip nixpkgs.zip
mv nixpkgs-* nixpkgs
export NIX_PATH=nixpkgs=$HOME/nixpkgs

parted -s /dev/sda -- mklabel gpt
parted -s /dev/sda -- mkpart root xfs 512MB -2GB
parted -s /dev/sda -- mkpart swap linux-swap -2GB 100%
parted -s /dev/sda -- mkpart ESP fat32 1MB 512MB
parted -s /dev/sda -- set 3 esp on

mkfs.ext4 -L nixos /dev/sda1
mkswap -L swap /dev/sda2
mkfs.fat -F 32 -n boot /dev/sda3

mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount -o umask=077 /dev/disk/by-label/boot /mnt/boot
swapon /dev/sda2

mkdir /mnt/nix
unsquashfs -d /mnt/nix/store nixos/nix-store.squashfs

nixos-generate-config --root /mnt

cat > /mnt/etc/nixos/configuration.nix <<EOL
{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    tmux
    openssh
    pkgs.util-linux
  ];

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "prohibit-password";

  users.users.root.openssh.authorizedKeys.keys = [
    "${ssh_public_key}"
  ];

  system.stateVersion = "${nixos_version}";
}
EOL

nixos-install --no-root-passwd --root /mnt

rm -rf /mnt/root/.nix-profile
rm -rf /mnt/root/.nix-defexpr
rm -rf /mnt/root/.nix-channels

rm -rf /tmp/*
nix-collect-garbage -d
rm -rf /var/log/*
