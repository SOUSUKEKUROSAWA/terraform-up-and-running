# 詳解Terraform

## chocolateyのインストールと使用法

管理者権限でしかインストールできないので注意

- エクスプローラで Windows Powershell を検索し，「管理者で実行」を選択する
- <https://chocolatey.org/install> にあるコマンドをコピーして実行する

```sh
# インストール
choco install terraform

# インストールしたパッケージの確認
choco list
```

※これ以降のterraformコマンドも管理者権限でしか実行する

## AWS認証情報の設定

```sh
set AWS_ACCESS_KEY_ID=<access-key-id>
set AWS_SECRET_ACCESS_KEY=<secret-access-key>
```
