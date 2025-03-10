# 詳解Terraform

## サンプルコード

<https://github.com/brikis98/terraform-up-and-running-code>

## chocolateyの利用

管理者権限でしかインストールできないので注意．

- エクスプローラで Windows sh を検索し，「管理者で実行」を選択する
- <https://chocolatey.org/install> にあるコマンドをコピーして実行する

※インストールなどPCに変更を加える操作は管理者権限で行う．その他の操作はCursor組み込みのPowerShellでも実行できる（Bashではできない）

```sh
# インストール
choco install terraform

# インストールしたパッケージの確認
choco list
```

※これ以降のterraformコマンドも管理者権限で実行する．

## AWS認証情報の管理

AWS CLI で管理

```sh
# インストール
choco install awscli

# AWS認証情報の入力
aws configure

# AWS認証情報の一覧を表示
aws configure list

# AWS認証情報の確認
cat $HOME\.aws\credentials

# AWS設定の確認
cat $HOME\.aws\config
```

AWS Vault でクレデンシャルを管理
（内部でOSのネイティブなパスワードマネージャを使用している）

```sh
# インストール
choco install aws-vault

# AWSクレデンシャルの登録
aws-vault add default

# 登録されているクレデンシャルの一覧を表示
aws-vault ls

# プロフィールの追加
vim $HOME\.aws\config

[default]
region=us-east-2
output=json

[profile self-study]
region=us-east-2
mfa_serial=arn:aws:iam::xxx:mfa/xxx
source_profile=default

# セッションクリア
aws-vault clear

# aws-vault exec コマンド実行時に生成される一時的な環境変数の表示
aws-vault exec self-study -- env | grep AWS
```

※MFAを有効化しないとIAMユーザーの作成でエラーが出るので注意

```sh
│ Error: creating IAM User (module.foreach.neo): operation error IAM: CreateUser, https response error StatusCode: 403, RequestID: xxx, api error InvalidClientTokenId: The security token included in the request is invalid
│
│   with module.users_foreach["neo"].aws_iam_user.example,
│   on .terraform\modules\users_foreach\landing-zone\iam-user\main.tf line 1, in resource "aws_iam_user" "example":
│    1: resource "aws_iam_user" "example" {
```

## Terraformの利用

```sh
# ディレクトリに移動
cd $HOME\Documents\terraform-up-and-running\stage\data-stores\mysql
cd $HOME\Documents\terraform-up-and-running\stage\services\web-server-cluster
cd $HOME\Documents\terraform-up-and-running\prod\data-stores\mysql
cd $HOME\Documents\terraform-up-and-running\prod\services\web-server-cluster
cd $HOME\Documents\terraform-up-and-running\global\iam
cd $HOME\Documents\terraform-up-and-running\global\provisioner

# そのディレクトリで使用するプロバイダのコード（バイナリ）を読み込む
aws-vault exec self-study -- terraform init -backend-config="$HOME\Documents\terraform-up-and-running\backend.hcl"

# どのような変更があるかを確認
aws-vault exec self-study -- terraform plan

# リソースをデプロイ
aws-vault exec self-study -- terraform apply

# リソースの一覧を表示
aws-vault exec self-study -- terraform state list

# リソースの依存グラフを表示（Graphvizなどで可視化できるDOT言語で書かれている）
aws-vault exec self-study -- terraform graph

# 変更を適用せずに出力だけを表示
aws-vault exec self-study -- terraform output
aws-vault exec self-study -- terraform output <出力変数名>

# 全てのリソースの削除
# -- ステートファイルも一緒に更新されるので，terraform applyを実行すればリソースの再作成は行える．
# -- ただし，リソースに保存されていたデータなど，Terraform管理できていないデータは復元されないので注意．
aws-vault exec self-study -- terraform destroy

# terraformの文法でインフラのステートの読み出しができるインタラクティブコンソールを開く
# -- 読み出し専用なので，インフラのステートを変更してしまう危険性はない
aws-vault exec self-study -- terraform console

# ロックの強制開放
aws-vault exec self-study -- terraform force-unlock <ロックID>
```

依存グラフを可視化するオンラインツール

- [GraphvizOnline](https://bit.ly/2mPbxmg)

リソースのリプレイス

- `# forces replacement`で検索することでリプレイスされる部分がわかる

## AWS CLIの利用

chocolateyでインストール後，セッションを一度閉じてから，再度開くとパスが通った状態になる．

```sh
# インスタンス名を変数に格納
$instanceName = "webservers-stage"
$instanceName = "webservers-prod"

# 全てのEC2インスタンスIDを取得
aws-vault exec self-study -- aws ec2 describe-instances --query "Reservations[*].Instances[*].InstanceId" --output text

# 特定のインスタンス名を持つEC2インスタンスのIDを取得
aws-vault exec self-study -- aws ec2 describe-instances --filters "Name=tag:Name,Values=$instanceName" --query "Reservations[*].Instances[*].InstanceId" --output text

# 特定のインスタンス名を持ち，ステータスがterminated状態でないEC2インスタンスのIDを取得
aws-vault exec self-study -- aws ec2 describe-instances --filters "Name=tag:Name,Values=$instanceName" "Name=instance-state-name,Values=pending,running,stopping,stopped" --query "Reservations[*].Instances[*].InstanceId" --output text

# インスタンスIDを変数に格納
$instanceId = "<インスタンスID>"

# 指定したインスタンスを停止
aws-vault exec self-study -- aws ec2 stop-instances --instance-ids $instanceId

# 指定したインスタンスを起動
aws-vault exec self-study -- aws ec2 start-instances --instance-ids $instanceId

# 指定したインスタンスの状態を取得
aws-vault exec self-study -- aws ec2 describe-instances --instance-ids $instanceId --query "Reservations[*].Instances[*].State.Name" --output text

# 指定したインスタンスのパブリックIPを取得
aws-vault exec self-study -- aws ec2 describe-instances --instance-ids $instanceId --query "Reservations[*].Instances[*].PublicIpAddress" --output text
```

## Auto Scaling Group（ASG）

動作検証

- **数分のラグはある**が，インスタンスを手動で削除して`min_size`を下回ると自動で新たなインスタンスが作成されることを確認

ASG内のインスタンスをすべて停止させる方法

- `min_size`と`max_size`を両方0にする

```sh
# アカウント上の全てのASGを取得
aws-vault exec self-study -- aws autoscaling describe-auto-scaling-groups

# オートスケーリンググループ名を変数に格納
$autoScalingGroupName = "webservers-stage"
$autoScalingGroupName = "webservers-prod"

# 特定の名前のASGを取得
aws-vault exec self-study -- aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $autoScalingGroupName
```

## Elastic Load Balancing（ELB）

Apply後，インスタンスが起動し，ALBに正常として表示されるようになるまで数分かかる

※課金されないように停止させておくことはできないためリソースを削除する必要あり

動作検証

- 特定のインスタンスを停止させてもリクエストが送り続けられることを確認
- 特定のインスタンスを停止させてから少し経つと新しいインスタンスが起動されることを確認
  - 停止させたインスタンスが`unused→draining`になった後，新たなインスタンスが起動され，`unhealthy→healthy`になってオートヒーリングすることを確認
  - この間ずっとリクエストは成功し続ける

```sh
# リージョン上の全てのALBを取得
aws-vault exec self-study -- aws elbv2 describe-load-balancers

# ALB名を変数に格納
$applicationLoadBalancerName = "webservers-stage"
$applicationLoadBalancerName = "webservers-prod"

# 特定の名前のALBを取得
aws-vault exec self-study -- aws elbv2 describe-load-balancers --names $applicationLoadBalancerName

# 全てのターゲットグループを取得
aws-vault exec self-study -- aws elbv2 describe-target-groups

# ターゲットグループ名を変数に格納
$targetGoupName = "terraform-asg-example"

# 特定の名前のターゲットグループの取得
aws-vault exec self-study -- aws elbv2 describe-target-groups --names $targetGoupName

# ターゲットグループ名を変数に格納
$targetGroupArn=$(aws-vault exec self-study -- aws elbv2 describe-target-groups --query "TargetGroups[?TargetGroupName=='$targetGoupName'].TargetGroupArn" --output text)

# 特定のARNのターゲットグループがヘルスチェックを行っているインスタンスの一覧
aws-vault exec self-study -- aws elbv2 describe-target-health --target-group-arn $targetGroupArn
```

## RDS

```sh
# すべてのRDSインスタンスを取得
aws-vault exec self-study -- aws rds describe-db-instances --query "DBInstances[*].DBInstanceIdentifier" --output text

# 起動中のRDSインスタンスをすべて取得
aws-vault exec self-study -- aws rds describe-db-instances --query "DBInstances[?DBInstanceStatus=='available'].DBInstanceIdentifier" --output text
```

## ステートの管理

```sh
$bucketName = "terraform-up-and-running-backend"

# 特定のS3の特定のパスに配置されているファイルの一覧を表示
aws-vault exec self-study -- aws s3 ls s3://$bucketName/global/s3/

# 特定のS3の特定のファイルの内容を表示
aws-vault exec self-study -- aws s3 cp s3://$bucketName/stage/services/web-server-cluster/terraform.tfstate -
aws-vault exec self-study -- aws s3 cp s3://$bucketName/stage/data-stores/mysql/terraform.tfstate -

# 特定のS3の特定のファイルのバージョン履歴を表示
aws-vault exec self-study -- aws s3api list-object-versions --bucket $bucketName --prefix stage/services/web-server-cluster/terraform.tfstate

$versionId = "<バージョンID>"

# 特定のS3の特定のファイルを特定のバージョンにロールバックする
aws-vault exec self-study -- aws s3api copy-object --bucket $bucketName --copy-source $bucketName/stage/services/web-server-cluster/terraform.tfstate?versionId=$versionId --key stage/services/web-server-cluster/terraform.tfstate

$tableName = "terraform-up-and-running-locks"

# 特定のDynamoDBテーブルのデータの一覧を表示
aws-vault exec self-study -- aws dynamodb scan --table-name $tableName

# 特定のDynamoDBテーブルの特定のデータの削除
# -- Windows shでは，シングルクォートでJSON全体を囲んで，JSON内のダブルクォートはエスケープしてやる必要がある
aws-vault exec self-study -- aws dynamodb delete-item --table-name $tableName --key '{\"LockID\": {\"S\": \"terraform-up-and-running-backend/stage/data-stores/mysql/terraform.tfstate-md5\"}}'
```

## ステートファイルの分離

- デプロイの頻度ごとに分かれている方がリスクが減る
- 環境ごとに分かれている方がリスクが減る
- 全環境共通のリソースは global ディレクトリに

## モジュール

init コマンドの役割

- プロバイダのインストール，バックエンド設定のほかに，モジュールのダウンロードも行うので，モジュールを新たに利用する際は init コマンドも実行し直す必要がある

## ローカル変数

使うタイミング

- DRYを保つために変数化したいけど，入力変数（variables）として上書き可能な状態にはしたくない時

## モジュールの注意点

### ファイルパス

Terraformはデフォルトではカレントディレクトリ（terraformコマンドを実行する場所）に対する相対パスであると判断するので，パス参照をうまく使うこと

- `path.module`
  - 定義があるモジュールが存在するディレクトリのパスを返す
- `path.root`
  - terraform init コマンドを打ったディレクトリを返す
- `path.cwd`
  - 基本 path.root と同じ値を返す
  - ルートモジュール以外の場所でTerraformを実行する特殊な場合，path.root と異なる値になる

### インラインブロック

リソースの中にインラインブロックとしても定義できるし，別のリソースとしても定義できるものが存在するが，モジュールの場合は別リソースとして定義した方が，モジュール利用側で追加がしやすい

> p.128 参照

### セマンティックバージョニング

MAJOR.MINOR.PATCH（ex. 1.4.2）

どのタイミングでインクリメントするか

- MAJOR
  - APIの互換性が無くなる時
- MINOR
  - 後方互換性のある機能を追加する時
- PATCH
  - 後方互換性のあるバグ修正を行うとき

モジュールは以下のリポジトリに移行

- <https://github.com/SOUSUKEKUROSAWA/terraform-up-and-running-module>

## countパラメータの落とし穴

- リソース以外の反復に使えない
  - インラインブロックを反復したりできない
- countの途中のリソースを削除しようとすると，削除しようとした要素移行のアイテムを全部削除し，ゼロから作り直そうとしてしまう
  - この問題を解消するために for_each が導入された

## ループのベストプラクティス

- count
  - 条件付きリソースに使う（作成するかしないかを動的に決定する）
- for_each
  - リソースの繰り返しに使う
  - インラインブロックの繰り返しに使う
- for
  - 1つの変数あるいはパラメータの繰り返しに使う
  - python の for 式のような柔軟さがある

## AWS Secrets Manager

```sh
$secretName = db-credentials

# シークレットの作成
aws-vault exec self-study -- aws secretsmanager create-secret --name $secretName --secret-string file://db-credentials.json

# シークレットの取得
aws-vault exec self-study -- aws secretsmanager get-secret-value --secret-id $secretName
```

## プロバイダ

required_providers

- terraform init でダウンロードするプロバイダのコードを固定できる
- .terraform.lock.hcl があればコードは固定されるけど，初回の terraform init からコードを固定するには required_providers が必要

## kubectl

Docker DesktopでKubernetesを有効にすると，自動的に`$HOME\.kube\config`が変更されて`docker-desktop`エントリが追加される

```sh
# インストール
choco install kubernetes-cli

# インストール後のチェック
kubectl version --output=yaml

# Docker Desktopによって追加されたエントリを使用するようにする
kubectl config use-context docker-desktop

# 全ノード（コントロールプレーンも含む）の表示
aws-vault exec self-study -- kubectl get nodes --output=json

aws-vault exec self-study -- kubectl get deployments

aws-vault exec self-study -- kubectl get pods

aws-vault exec self-study -- kubectl get services

# kubectlをEKSクラスタに認証させるため，自動的にconfigファイルを更新
aws-vault exec self-study -- aws eks update-kubeconfig --region us-east-2 --name example-eks-cluster
```

## example ディレクトリ

モジュールの利用を試せるようなコード群を配置しておくとGOOD

新しくモジュールを作成する場合は，まず利用側のサンプルコードから書き始めると，使いやすいモジュールが作りやすくなる

## validation, precondition, postcondition の使い分け

- validation
  - 基本的な入力のサニタイズ
    - precondition の方が強力だが，validation の方が変数と一緒に定義されるので可読性が高く，メンテもしやすい
- precondition
  - validation が使えない状況での基本的な前提のチェック
    - 複数の変数やデータソースを参照するチェックなど
- postcondition
  - Apply後の基本的なふるまいのチェック
- さらに高度な前提条件やふるまい
  - 自動テストツールを使う
    - OPA
    - Terratest

## provisioner と user_data

基本 user_data の方が上位互換

ただ，user_data はスクリプトの長さが 16KB に制限されているが，provisioner は無制限なので，16KB 以上のスクリプトになる場合は provisioner を使う
