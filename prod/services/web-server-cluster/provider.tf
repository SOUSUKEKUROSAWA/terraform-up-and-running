provider "aws" {
    region = "us-east-2"

    # モジュール内で作成するすべてのリソースにデフォルトで適用するタグ
    # -- リソースごとにこのタグを上書きすることは許容される
    default_tags {
        tags = {
            ManagedBy = "Terraform"
        }
    }
}