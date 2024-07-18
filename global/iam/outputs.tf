# countで定義したリソースの一部にアクセスする場合
output "first_arn" {
    value = aws_iam_user.example[0].arn
    description = "The ARN for the first user"
}

# countで定義したリソースの全てにアクセスする場合
output "all_arns" {
    value = aws_iam_user.example[*].arn
    description = "The ARNs for all users"
}

output "user_arns" {
    value = module.users[*].user_arn
    description = "The ARNs of the created IAM users"
}

# for_eachを使った場合
output "all_users" {
    value = aws_iam_user.example_foreach # キーがfor_eachのキー（ユーザー名）のマップが出力される
}

output "all_arns_foreach" {
    value = values(aws_iam_user.example_foreach)[*].arn # 個々の値にアクセスする
}

output "user_arns_foreach" {
    value = values(module.users_foreach)[*].user_arn
    description = "The ARNs of the created IAM users"
}

# if-elseでリソースを作成するためARNを動的に出力
# -- oneとconcatにより，if-elseの条件分岐に依存しない出力定義になっている
# -- concat() ２つのリストを１つに結合
# -- one() 1つのリストの要素数が，0ならnull，1ならそのまま，複数ならエラー，を返す
output "neo_cloudwatch_policy_arn" {
    value = one(concat(
        aws_iam_user_policy_attachment.neo_cloudwatch_full_access[*].policy_arn,
        aws_iam_user_policy_attachment.neo_cloudwatch_read_only[*].policy_arn
    ))
}