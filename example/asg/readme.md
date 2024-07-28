# cluster/asg-rolling-deploy のテストハーネス

モジュールの利用例があることで以下のメリットが得られる

- 手動テストのハーネス
  - planとapplyを試せる
- 自動テストのハーネス
  - 自動テストに組み込める
- 実行可能なドキュメント
  - このモジュールによって作成されるリソースを試せる

## source

<https://github.com/SOUSUKEKUROSAWA/terraform-up-and-running-module/tree/main/cluster/asg-rolling-deploy>

## Run

```sh
cd $HOME\Documents\terraform-up-and-running\example\asg

aws-vault exec self-study -- terraform init -backend-config="$HOME\Documents\terraform-up-and-running\backend.hcl"

aws-vault exec self-study -- terraform apply
```

## Reset

```sh
aws-vault exec self-study -- terraform destroy
```
