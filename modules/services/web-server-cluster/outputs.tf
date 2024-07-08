# モジュールで定義された出力変数はモジュール利用側で使えるようになるだけ
# -- Applyで出力するには，利用側の outputs.tf でここで定義した変数を指定してあげる必要があるので注意
output "alb_dns_name" {
    value = aws_lb.example.dns_name
    description = "The domain name of the load balancer"
}

output "asg_name" {
    value = aws_autoscaling_group.example.name
    description = "The name of the Auto Scaling Group"
}

output "alb_security_group_id" {
    value = aws_security_group.alb.id
    description = "The ID of the Security Group attached to the load balancer"
}