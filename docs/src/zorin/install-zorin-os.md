# Install Zorin OS 18

## Download

[https://zorin.com/os/mirrors/](https://zorin.com/os/mirrors/) にアクセスしてお住まいの地域に近い mirror server を選択します。

遷移先のページでインストールしたい OS のバージョンを選択します。
ここでは `Zorin-OS-18-Core-64-bit.iso` をダウンロードしました。

### Check SHA-256 hash

[https://help.zorin.com/docs/getting-started/check-the-integrity-of-your-copy-of-zorin-os/#correct-sha256-checksums](https://help.zorin.com/docs/getting-started/check-the-integrity-of-your-copy-of-zorin-os/#correct-sha256-checksums) にアクセスして、ISO Image の SHA256 の期待値を確認します。

Zorin OS 18 Core の場合は:
>98666287ca5afae215def4804aca479bf3b439e028bc8f4e4d8ecddb6dd27339

次にターミナルから実際にダウンロードした ISO ファイルの checksum を確認します。

```bash
$ sha256sum Zorin-OS-18-Core-64-bit.iso 
98666287ca5afae215def4804aca479bf3b439e028bc8f4e4d8ecddb6dd27339  Zorin-OS-18-Core-64-bit.iso
```

一致しているので問題ないです。

## Create a Live USB
