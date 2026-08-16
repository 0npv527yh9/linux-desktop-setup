#!/bin/bash

set -e

# Install the keyd configuration.
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_file="$script_dir/keyd/default.conf"
target_file="/etc/keyd/default.conf"

# Preserve an existing configuration when its contents differ.
if sudo test -f "$target_file" && ! sudo cmp -s "$source_file" "$target_file"; then
  backup_file="${target_file}.backup.$(date +%Y%m%d%H%M%S)"
  sudo cp "$target_file" "$backup_file"
  echo "Backed up the existing configuration to $backup_file"
fi

sudo install -D -m 0644 "$source_file" "$target_file"
sudo keyd reload

echo "Installed $target_file"
