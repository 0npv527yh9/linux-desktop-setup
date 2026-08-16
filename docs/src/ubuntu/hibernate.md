# Enable Hibernate

swapfile を使った Hibernate（休止状態）の設定を行います。

> [!WARNING]
> Hibernate はハードウェア、ファームウェア、ドライバー、カーネルに依存します。復帰に失敗する可能性があるため、最初のテスト前に作業を保存し、重要なデータをバックアップしてください。この記事に記載した UUID とオフセットの例をコピーせず、必ず自分の環境の値を使います。

## 環境

- Surface Pro 2017（RAM 約 8 GiB）
- Ubuntu 24.04 LTS
- カーネル `7.0.0-28-generic`
- systemd 255
- ext4 上の `/swap.img`（8 GiB）
- Secure Boot: 無効

この環境で利用可能なメモリスリープ方式は `s2idle` のみで、`deep`（S3）は利用できませんでした。一方、カーネルは Suspend-to-Disk に対応していました。

## 事前確認

カーネルが公開している電源状態、メモリスリープ方式、メモリと swap を確認します。

```bash
cat /sys/power/state
cat /sys/power/mem_sleep
free -h
swapon --show
findmnt -no SOURCE,FSTYPE,UUID /
```

`/sys/power/state` に `disk` が含まれること、Hibernate イメージを保存できる容量の swap が有効であることを確認します。

## swapfile の復帰先を調べる

ルートファイルシステムの UUID を取得します。

```bash
findmnt -no UUID /
```

次に `/swap.img` の物理オフセットを取得します。ext4 では `filefrag` の最初の extent の `physical_offset` を使います。

```bash
sudo filefrag -v /swap.img
```

出力例:

```text
File size of /swap.img is ...
 ext: logical_offset: physical_offset: ...
   0:        0..:       22149120..: ...
```

この例のオフセットは `22149120` です。以降の `<ROOT_UUID>` と `<RESUME_OFFSET>` は、自分の環境で取得した値に置き換えます。

> [!NOTE]
> Btrfs の swapfile では取得方法が異なります。この手順は ext4 を対象としています。

## GRUB に復帰先を設定する

`/etc/default/grub.d/99-hibernate.cfg` を作成します。

```sh
GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT resume=UUID=<ROOT_UUID> resume_offset=<RESUME_OFFSET>"
```

`resume` には swapfile 自体ではなく、それを格納するファイルシステムの UUID を指定します。

## initramfs に復帰先を設定する

`/etc/initramfs-tools/conf.d/resume` を作成します。

```text
RESUME=UUID=<ROOT_UUID>
```

## systemd で Hibernate を許可する

この端末では systemd の自動判定が Hibernate を利用不可としたため、`/etc/systemd/sleep.conf.d/99-hibernate.conf` で明示的に許可しました。

```ini
[Sleep]
AllowHibernation=yes
HibernateMode=platform shutdown
AllowSuspendThenHibernate=yes
HibernateDelaySec=60min
```

この指定をしても、この環境の `CanHibernate` は `no` のままでしたが、後述の実機テストでは Hibernate と復帰に成功しました。判定を上書きして試す場合は、復帰できない可能性を前提にしてください。

## 起動環境を再生成する

```bash
sudo update-initramfs -u -k all
sudo update-grub
sudo reboot
```

swap パーティションではなく swapfile を使っているため、`update-initramfs` が UUID に一致する swap デバイスがないという警告を出す場合があります。この環境では、カーネル引数の `resume_offset` と組み合わせることで復帰できました。

## 再起動後に設定を確認する

カーネル引数に `resume` と `resume_offset` が含まれることを確認します。

```bash
cat /proc/cmdline
cat /sys/power/resume
cat /sys/power/resume_offset
```

systemd の判定も確認できます。

```bash
busctl call org.freedesktop.login1 \
  /org/freedesktop/login1 \
  org.freedesktop.login1.Manager CanHibernate
```

## 実機でテストする

未保存の作業がないことを確認して実行します。

```bash
systemctl hibernate
```

画面が消えても、イメージの書き込みが終わる前に電源ボタンを押さないようにします。この端末では約 60 秒待ち、電源が切れた後で電源ボタンを押しました。復帰後、稼働時間がリセットされず、元のセッションと周辺機器が復元されたことを確認しました。

確認した項目:

- 画面表示
- Type Cover のキーボードとタッチパッド
- タッチパネル
- Wi-Fi と音声
- Ubuntu を格納した USB ドライブ
- 開いていたセッション

1 回目は保存処理中に電源ボタンを押したため、`Wakeup event detected during hibernation, rolling back` となりました。2 回目は操作せずに待ち、Hibernate から正常に復帰しました。

## GNOME での運用

この環境では GNOME の `gsd-power` がふた閉じイベントを処理していたため、`logind.conf` の `HandleLidSwitch=suspend-then-hibernate` は GNOME ログイン中に適用されませんでした。ふた閉じは既定の Suspend のままとし、長時間使わない場合は先に `systemctl hibernate` を実行しています。

GNOME の無操作時動作を変更する場合は、現在値を控えてから `gsettings` で設定します。

```bash
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 3600
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'hibernate'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 3600
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'hibernate'
```

## 運用上の注意

- Hibernate 中および復帰前に Ubuntu の USB ドライブを外さない
- Hibernate 後、復帰する前に別の OS から Ubuntu のファイルシステムを変更しない
- `/swap.img` を削除、再作成、移動、デフラグした場合はオフセットを再取得する
- 短時間の離席には Suspend、長時間使わない場合には動作確認済みの Hibernate またはシャットダウンを使う

## 設定を元に戻す

作成した設定ファイルを削除し、起動環境を再生成してから再起動します。

```bash
sudo rm /etc/default/grub.d/99-hibernate.cfg
sudo rm /etc/initramfs-tools/conf.d/resume
sudo rm /etc/systemd/sleep.conf.d/99-hibernate.conf
sudo update-initramfs -u -k all
sudo update-grub
sudo reboot
```

## 参考資料

- [Linux kernel: Swap suspend](https://docs.kernel.org/power/swsusp.html)
- [Linux kernel: System Sleep States](https://docs.kernel.org/admin-guide/pm/sleep-states.html)
- [systemd sleep.conf](https://www.freedesktop.org/software/systemd/man/latest/systemd-sleep.conf.html)
- [Ubuntu Help: Why does my computer turn off when I close the lid?](https://help.ubuntu.com/stable/ubuntu-help/power-closelid.html.en)
