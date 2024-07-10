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