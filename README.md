# 詳解Terraform

## サンプルコード

<https://github.com/brikis98/terraform-up-and-running-code>

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

※これ以降のterraformコマンドも管理者権限で実行する．

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
cd $HOME\Documents\terraform-up-and-running\stage\data-stores\mysql
cd $HOME\Documents\terraform-up-and-running\stage\services\web-server-cluster
cd $HOME\Documents\terraform-up-and-running\prod\data-stores\mysql
cd $HOME\Documents\terraform-up-and-running\prod\services\web-server-cluster

# そのディレクトリで使用するプロバイダのコード（バイナリ）を読み込む
terraform init -backend-config="$HOME\Documents\terraform-up-and-running\backend.hcl"

# どのような変更があるかを確認
terraform plan

# リソースをデプロイ
terraform apply

# リソースの一覧を表示
terraform state list

# リソースの依存グラフを表示（Graphvizなどで可視化できるDOT言語で書かれている）
terraform graph

# 変更を適用せずに出力だけを表示
terraform output
terraform output <出力変数名>

# 全てのリソースの削除
# -- ステートファイルも一緒に更新されるので，terraform applyを実行すればリソースの再作成は行える．
# -- ただし，リソースに保存されていたデータなど，Terraform管理できていないデータは復元されないので注意．
terraform destroy

# terraformの文法でインフラのステートの読み出しができるインタラクティブコンソールを開く
# -- 読み出し専用なので，インフラのステートを変更してしまう危険性はない
terraform console
```

依存グラフを可視化するオンラインツール

- [GraphvizOnline](https://bit.ly/2mPbxmg)

リソースのリプレイス

- `# forces replacement`で検索することでリプレイスされる部分がわかる

## AWS CLIの利用

chocolateyでインストール後，セッションを一度閉じてから，再度開くとパスが通った状態になる．

```powershell
# インスタンス名を変数に格納
$instanceName = "webservers-stage"
$instanceName = "webservers-prod"

# 全てのEC2インスタンスIDを取得
aws ec2 describe-instances --query "Reservations[*].Instances[*].InstanceId" --output text

# 特定のインスタンス名を持つEC2インスタンスのIDを取得
aws ec2 describe-instances --filters "Name=tag:Name,Values=$instanceName" --query "Reservations[*].Instances[*].InstanceId" --output text

# 特定のインスタンス名を持ち，ステータスがterminated状態でないEC2インスタンスのIDを取得
aws ec2 describe-instances --filters "Name=tag:Name,Values=$instanceName" "Name=instance-state-name,Values=pending,running,stopping,stopped" --query "Reservations[*].Instances[*].InstanceId" --output text

# インスタンスIDを変数に格納
$instanceId = "<インスタンスID>"

# 指定したインスタンスを停止
aws ec2 stop-instances --instance-ids $instanceId

# 指定したインスタンスを起動
aws ec2 start-instances --instance-ids $instanceId

# 指定したインスタンスの状態を取得
aws ec2 describe-instances --instance-ids $instanceId --query "Reservations[*].Instances[*].State.Name" --output text

# 指定したインスタンスのパブリックIPを取得
aws ec2 describe-instances --instance-ids $instanceId --query "Reservations[*].Instances[*].PublicIpAddress" --output text
```

## Auto Scaling Group（ASG）

動作検証

- **数分のラグはある**が，インスタンスを手動で削除して`min_size`を下回ると自動で新たなインスタンスが作成されることを確認

ASG内のインスタンスをすべて停止させる方法

- `min_size`と`max_size`を両方0にする

```powershell
# アカウント上の全てのASGを取得
aws autoscaling describe-auto-scaling-groups

# オートスケーリンググループ名を変数に格納
$autoScalingGroupName = "webservers-stage"
$autoScalingGroupName = "webservers-prod"

# 特定の名前のASGを取得
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $autoScalingGroupName
```

## Elastic Load Balancing（ELB）

Apply後，インスタンスが起動し，ALBに正常として表示されるようになるまで数分かかる

※課金されないように停止させておくことはできないためリソースを削除する必要あり

動作検証

- 特定のインスタンスを停止させてもリクエストが送り続けられることを確認
- 特定のインスタンスを停止させてから少し経つと新しいインスタンスが起動されることを確認
  - 停止させたインスタンスが`unused→draining`になった後，新たなインスタンスが起動され，`unhealthy→healthy`になってオートヒーリングすることを確認
  - この間ずっとリクエストは成功し続ける

```powershell
# リージョン上の全てのALBを取得
aws elbv2 describe-load-balancers

# ALB名を変数に格納
$applicationLoadBalancerName = "webservers-stage"
$applicationLoadBalancerName = "webservers-prod"

# 特定の名前のALBを取得
aws elbv2 describe-load-balancers --names $applicationLoadBalancerName

# 全てのターゲットグループを取得
aws elbv2 describe-target-groups

# ターゲットグループ名を変数に格納
$targetGoupName = "terraform-asg-example"

# 特定の名前のターゲットグループの取得
aws elbv2 describe-target-groups --names $targetGoupName

# ターゲットグループ名を変数に格納
$targetGroupArn=$(aws elbv2 describe-target-groups --query "TargetGroups[?TargetGroupName=='$targetGoupName'].TargetGroupArn" --output text)

# 特定のARNのターゲットグループがヘルスチェックを行っているインスタンスの一覧
aws elbv2 describe-target-health --target-group-arn $targetGroupArn
```

## RDS

```powershell
# すべてのRDSインスタンスを取得
aws rds describe-db-instances --query "DBInstances[*].DBInstanceIdentifier" --output text

# 起動中のRDSインスタンスをすべて取得
aws rds describe-db-instances --query "DBInstances[?DBInstanceStatus=='available'].DBInstanceIdentifier" --output text
```

## ステートの管理

```powershell
$bucketName = "terraform-up-and-running-backend"

# 特定のS3の特定のパスに配置されているファイルの一覧を表示
aws s3 ls s3://$bucketName/global/s3/

# 特定のS3の特定のファイルの内容を表示
aws s3 cp s3://$bucketName/stage/services/web-server-cluster/terraform.tfstate -
aws s3 cp s3://$bucketName/stage/data-stores/mysql/terraform.tfstate -

# 特定のS3の特定のファイルのバージョン履歴を表示
aws s3api list-object-versions --bucket $bucketName --prefix stage/services/web-server-cluster/terraform.tfstate

$versionId = "<バージョンID>"

# 特定のS3の特定のファイルを特定のバージョンにロールバックする
aws s3api copy-object --bucket $bucketName --copy-source $bucketName/stage/services/web-server-cluster/terraform.tfstate?versionId=$versionId --key stage/services/web-server-cluster/terraform.tfstate

$tableName = "terraform-up-and-running-locks"

# 特定のDynamoDBテーブルのデータの一覧を表示
aws dynamodb scan --table-name $tableName

# 特定のDynamoDBテーブルの特定のデータの削除
# -- Windows Powershellでは，シングルクォートでJSON全体を囲んで，JSON内のダブルクォートはエスケープしてやる必要がある
aws dynamodb delete-item --table-name $tableName --key '{\"LockID\": {\"S\": \"terraform-up-and-running-backend/stage/data-stores/mysql/terraform.tfstate-md5\"}}'
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
