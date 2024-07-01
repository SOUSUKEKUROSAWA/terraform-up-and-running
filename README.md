# 詳解Terraform

## chocolateyの利用

管理者権限でしかインストールできないので注意．

- エクスプローラで Windows Powershell を検索し，「管理者で実行」を選択する
- <https://chocolatey.org/install> にあるコマンドをコピーして実行する

```sh
# インストール
choco install terraform

# インストールしたパッケージの確認
choco list
```

※これ以降のterraformコマンドも管理者権限でしか実行する．

## AWS認証情報の管理

AWS CLI で管理

```powershell
# AWS認証情報の入力
aws configure

# AWS認証情報の一覧を表示
aws configure list

# AWS認証情報の確認
cat $HOME\.aws\credentials

# AWS設定の確認
cat $HOME\.aws\config
```

## Terraformの利用

```sh
# ディレクトリに移動
cd C:\Users\kuros\Documents\terraform-up-and-running

# そのディレクトリで使用するプロバイダのコード（バイナリ）を読み込む
terraform init

# どのような変更があるかを確認
terraform plan

# リソースをデプロイ
terraform apply

# リソースの一覧を表示
terraform state list

# リソースの依存グラフを表示（Graphvizなどで可視化できるDOT言語で書かれている）
terraform graph
```

依存グラフを可視化するオンラインツール

- [GraphvizOnline](https://bit.ly/2mPbxmg)

リソースのリプレイス

- `# forces replacement`で検索することでリプレイスされる部分がわかる

## AWS CLIの利用

chocolateyでインストール後，セッションを一度閉じ手から，再度開くとパスが通った状態になる．

```powershell
# 全てのEC2インスタンスIDを取得
aws ec2 describe-instances --query "Reservations[*].Instances[*].InstanceId" --output text

# 特定のインスタンス名を持つEC2インスタンスのIDを取得
aws ec2 describe-instances --filters "Name=tag:Name,Values=<インスタンス名>" --query "Reservations[*].Instances[*].InstanceId" --output text

# 特定のインスタンス名を持ち，ステータスがterminated状態でないEC2インスタンスのIDを取得
aws ec2 describe-instances --filters "Name=tag:Name,Values=<インスタンス名>" "Name=instance-state-name,Values=pending,running,stopping,stopped" --query "Reservations[*].Instances[*].InstanceId" --output text

# 指定したインスタンスを停止
aws ec2 stop-instances --instance-ids <インスタンスID>

# 指定したインスタンスを起動
aws ec2 start-instances --instance-ids <インスタンスID>

# 指定したインスタンスの状態を取得
aws ec2 describe-instances --instance-ids <インスタンスID> --query "Reservations[*].Instances[*].State.Name" --output text

# 指定したインスタンスのパブリックIPを取得
aws ec2 describe-instances --instance-ids <インスタンスID> --query "Reservations[*].Instances[*].PublicIpAddress" --output text
```
