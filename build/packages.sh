#!/bin/bash

# profiles
cat <<-eof | sudo tee /etc/profile.d/editor.sh
export EDITOR="vim"
eof

cat <<-eof | sudo tee /etc/profile.d/wayland.sh
export WAYLAND_DISPLAY=wayland-99
eof

# kernel
sudo apt update
sudo apt install -y linux-generic-hwe-18.04

# packages
sudo apt update
sudo apt install -y \
  apt-transport-https \
  apt-utils \
  ca-certificates \
  curl \
  ifupdown \
  lldpd \
  net-tools \
  numad \
  open-iscsi \
  software-properties-common \
  squashfs-tools \
  squashfuse \
  thin-provisioning-tools

# netq-agent
curl -k https://apps3.cumulusnetworks.com/setup/cumulus-apps-deb.pubkey | sudo apt-key add -
sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apps3.cumulusnetworks.com/repos/deb $(lsb_release -cs) netq-latest"
apt update
sudo apt install -y netq-agent

# snaps
sudo snap install \
  lxd \
  ubuntu-frame \
  wpe-webkit-mir-kiosk \
  uboot-tools
sudo snap install --candidate multipass

# upgrade
apt list --upgradable
sudo apt update
sudo apt upgrade -y
