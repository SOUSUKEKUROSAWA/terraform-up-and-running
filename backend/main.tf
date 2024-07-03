provider "aws" {
    region = "us-east-2"
}

terraform {
    backend "s3" {
        bucket = "terraform-up-and-running-backend"
        key = "global/s3/terraform.tfstate"
        region = "us-east-2"
        dynamodb_table = "terraform-up-and-running-locks"
        encrypt = true
    }
}

resource "aws_s3_bucket" "terraform_state" {
    bucket = "terraform-up-and-running-backend"

    # Terraformが誤ってこのリソースを削除できないようにする
    lifecycle {
        prevent_destroy = true
    }
}

# ステートファイルのバージョン管理を有効化
resource "aws_s3_bucket_versioning" "enabled" {
    bucket = aws_s3_bucket.terraform_state.id
    versioning_configuration {
        status = "Enabled"
    }
}

# 他の設定より優先して，このバケットに対する全てのパブリックアクセスをブロック
resource "aws_s3_bucket_public_access_block" "public_access" {
    bucket = aws_s3_bucket.terraform_state.id
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

# ステートファイルの整合性を保つためのロックテーブル
resource "aws_dynamodb_table" "terraform_locks" {
    name = "terraform-up-and-running-locks"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }
}

# リモートバックエンド（S3）との疎通確認
output "s3_bucket_arn" {
    value = aws_s3_bucket.terraform_state.arn
    description = "The ARN of the S3 bucket"
}

output "dynamodb_table_name" {
    value = aws_dynamodb_table.terraform_locks.name
    description = "The name of the DynamoDB table"
}