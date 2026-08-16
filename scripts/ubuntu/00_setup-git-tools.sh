#!/bin/bash

set -e

# Remove temporary files when the script exits.
out=""
tmp_dir=""
cleanup() {
  [ -z "$out" ] || rm -f "$out"
  [ -z "$tmp_dir" ] || rm -rf "$tmp_dir"
}
trap cleanup EXIT

# Git
sudo add-apt-repository ppa:git-core/ppa -y

# GitHub CLI
# https://github.com/cli/cli/blob/trunk/docs/install_linux.md
# Add the official GitHub CLI APT repository.
(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
  && sudo mkdir -p -m 755 /etc/apt/keyrings \
  && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
  && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && sudo mkdir -p -m 755 /etc/apt/sources.list.d \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# Install Git tools and their prerequisites.
sudo apt update
sudo apt install -y git ca-certificates curl wget gpg gh unzip

# Authenticate only when no valid GitHub CLI session exists.
if ! gh auth status >/dev/null 2>&1; then
  gh auth login
fi

# ghq
# Select the release asset for the current architecture.
case "$(dpkg --print-architecture)" in
  amd64)
    ghq_arch="amd64"
    ;;
  arm64)
    ghq_arch="arm64"
    ;;
  *)
    echo "Unsupported architecture: $(dpkg --print-architecture)" >&2
    exit 1
    ;;
esac

# Download the latest ghq release
tmp_dir="$(mktemp -d)"
asset="ghq_linux_${ghq_arch}.zip"

gh release download \
  --repo x-motemen/ghq \
  --pattern "$asset" \
  --dir "$tmp_dir"

# Install ghq
unzip -q "$tmp_dir/$asset" -d "$tmp_dir"
install -D -m 0755 \
  "$tmp_dir/ghq_linux_${ghq_arch}/ghq" \
  "$HOME/.local/bin/ghq"

# Verify the installed commands.
git --version
gh --version | head -1
ghq --version
