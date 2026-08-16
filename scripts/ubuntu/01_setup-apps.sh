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

# Install apps and system packages
sudo apt update
sudo apt install -y build-essential clang mold firefox code nushell fzf systemd-zram-generator

# NVM and the latest LTS version of Node.js
# https://github.com/nvm-sh/nvm#installing-and-updating
if [ ! -s "$HOME/.nvm/nvm.sh" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.6/install.sh | bash
fi

export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm alias default 'lts/*'

# Rust
# https://rust-lang.org/tools/install/
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# mold
cargo_dir="$HOME/.cargo"
cargo_config="$cargo_dir/config.toml"
rust_host="$($cargo_dir/bin/rustc -vV | sed -n 's/^host: //p')"
mold_config="[target.$rust_host]
linker = \"clang\"
rustflags = [\"-C\", \"link-arg=-fuse-ld=mold\"]"

mkdir -p "$cargo_dir"
printf '%s\n' "$mold_config" >"$cargo_config"

# uv
# https://docs.astral.sh/uv/getting-started/installation/
curl -LsSf https://astral.sh/uv/install.sh | sh

# keyd
# https://github.com/rvaiya/keyd#installation
keyd_version="v2.6.0"
keyd_repo="github.com/rvaiya/keyd"
keyd_clone_url="git@github.com:rvaiya/keyd.git"
keyd_dir="$(ghq root)/$keyd_repo"

# Clone or update the source under the ghq root.
ghq get "$keyd_clone_url"
git -C "$keyd_dir" fetch --tags
git -C "$keyd_dir" checkout --detach "$keyd_version"

# Build, install, and start keyd.
make -C "$keyd_dir"
sudo make -C "$keyd_dir" install
sudo systemctl enable --now keyd

# Verify the installed command.
keyd --version
