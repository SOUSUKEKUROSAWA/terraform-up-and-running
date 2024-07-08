# AWSが提供するデータソースからデフォルトVPC内のサブネットの情報を使える状態にする
data "aws_subnets" "default" {
    filter {
        name = "vpc-id"
        values = [data.aws_vpc.default.id]
    }
}

# AWSが提供するデータソースからデフォルトVPCの情報を使える状態にする
data "aws_vpc" "default" {
    default = true
}

# RDSのステートファイル上のデータ（出力変数など）を使える状態にする
data "terraform_remote_state" "db" {
    backend = "s3"

    config = {
        bucket = var.db_remote_state_bucket
        key = var.db_remote_state_key
        region = "us-east-2"
    }
}