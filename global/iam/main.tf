resource "aws_iam_user" "example" {
    count = length(var.user_names) # リソースをいくつ作成するかを指定．これで作成されるリソース群は配列的に扱える（リソースの配列）
    name = var.user_names[count.index]
}

# countはモジュールに対しても利用できる
module "users" {
    source = "github.com/SOUSUKEKUROSAWA/terraform-up-and-running-module//landing-zone/iam-user?ref=v0.0.2"

    count = length(var.user_names)
    user_name = "module.${var.user_names[count.index]}"
}