#!/bin/bash

set -e

# Visual Studio Code
# https://code.visualstudio.com/docs/setup/linux
wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
  | sudo gpg --dearmor --yes -o /usr/share/keyrings/microsoft.gpg

echo 'Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
' | sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null

# nushell
wget -qO- https://apt.fury.io/nushell/gpg.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/fury-nushell.gpg
echo "deb [signed-by=/etc/apt/keyrings/fury-nushell.gpg] https://apt.fury.io/nushell/ /" | sudo tee /etc/apt/sources.list.d/fury-nushell.list

# Install apps
sudo apt update
sudo apt install -y build-essential firefox code nushell

# Rust
# https://rust-lang.org/tools/install/
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# uv
# https://docs.astral.sh/uv/getting-started/installation/
curl -LsSf https://astral.sh/uv/install.sh | sh
