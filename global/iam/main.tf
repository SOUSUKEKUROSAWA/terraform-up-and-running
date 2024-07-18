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

# for_eachを使って同じことをする
# -- countと違ってマップとして出力されるため，中間リソースの削除が意図通り行える
resource "aws_iam_user" "example_foreach" {
    for_each = toset(var.user_names) # リソースが対象の場合，for_eachは集合（set）かマップしか対サポートしていないため集合に変換
    name = "foreach.${each.value}"
}

module "users_foreach" {
    source = "github.com/SOUSUKEKUROSAWA/terraform-up-and-running-module//landing-zone/iam-user?ref=v0.0.2"

    for_each = toset(var.user_names)
    user_name = "module.foreach.${each.value}"
}

# 条件付きリソース（if-else）
resource "aws_iam_user_policy_attachment" "neo_cloudwatch_full_access" {
    count = var.give_neo_cloudwatch_full_access ? 1 : 0 # if

    user = aws_iam_user.example[0].name
    policy_arn = aws_iam_policy.cloudwatch_full_access.arn
}

resource "aws_iam_user_policy_attachment" "neo_cloudwatch_read_only" {
    count = var.give_neo_cloudwatch_full_access ? 0 : 1 # else

    user = aws_iam_user.example[0].name
    policy_arn = aws_iam_policy.cloudwatch_read_only.arn
}

resource "aws_iam_policy" "cloudwatch_read_only" {
    name = "cloudwatch-read-only"
    policy = data.aws_iam_policy_document.cloudwatch_read_only.json
}

resource "aws_iam_policy" "cloudwatch_full_access" {
    name = "cloudwatch-full-access"
    policy = data.aws_iam_policy_document.cloudwatch_full_access.json
}