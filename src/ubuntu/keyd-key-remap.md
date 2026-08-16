# Remap Keys with keyd

JIS キーボードを `keyd` を使ってリマップします。
`keyd` は入力デバイスを扱うため、GNOME の Wayland セッションでも利用できます。

## 動作確認環境

- Surface Pro 2017
- Ubuntu 24.04.4 LTS
- GNOME / Wayland
- Mozc / IBus
- keyd 2.6.0

## インストール

[https://github.com/rvaiya/keyd](https://github.com/rvaiya/keyd) にしたがって install します。

```bash
sudo apt update
sudo apt install build-essential git
git clone git@github.com:rvaiya/keyd.git
cd keyd
make
sudo make install
sudo systemctl enable --now keyd
```

Ubuntu 25.04 以降では公式リポジトリのパッケージも利用できます。

```bash
sudo apt install keyd
sudo systemctl enable --now keyd
```

## 入力キー名を調べる

次のコマンドを実行してから対象キーを押します。

```bash
sudo keyd monitor
```

## 設定

`/etc/keyd/default.conf` を作成します。

```ini
# 例
[ids]
*

[main]
compose = rightcontrol
katakanahiragana = esc
```

この設定による割り当ては次のとおりです。

| 元のキー | 割り当て先 |
| --- | --- |
| コンテキストメニューキー (`compose`) | 右 Ctrl |
| カタカナ・ひらがなキー (`katakanahiragana`) | Escape |

設定を再読み込みします。

```bash
sudo keyd reload
```

設定エラーは次のコマンドで確認できます。

```bash
sudo journalctl -eu keyd
```

> [!WARNING]
> 誤った設定によってキーボードを操作できなくなった場合は、`Backspace`、`Escape`、`Enter` を同時に押すと `keyd` を停止できます。

## 無効にする場合

```bash
sudo systemctl disable --now keyd
```
