# Enable zram

zram を swap として利用し、メモリ上のデータを圧縮して保持します。ディスクへの swap より高速ですが、圧縮データ自体は RAM を消費します。

## インストール

Ubuntu 24.04 では、`systemd-zram-generator` パッケージを利用できます。

```bash
sudo apt update
sudo apt install systemd-zram-generator
sudo reboot
```

`zram-generator` は起動時に設定を読み、zramデバイスとswap用のsystemd unitを生成します。
ここでは独自の設定ファイルを作らず、パッケージの既定設定を使用しました。

- [Ubuntu Packages: systemd-zram-generator](https://packages.ubuntu.com/noble/systemd-zram-generator)
- [Ubuntu Manpage: zram-generator](https://manpages.ubuntu.com/manpages/noble/man8/zram-generator.8.html)

## 再起動後の確認

作成されたzramデバイスを確認します。

```bash
zramctl
```

有効なswapと優先度を確認します。

```bash
swapon --show
```

メモリとswap全体の使用量を確認します。

```bash
free -h
```

## 設定を変更する場合

サイズ、圧縮方式、swap優先度などは `zram-generator.conf` で変更できます。
設定ファイルは `/etc/systemd/zram-generator.conf` または `/etc/systemd/zram-generator.conf.d/*.conf` に配置できます。
