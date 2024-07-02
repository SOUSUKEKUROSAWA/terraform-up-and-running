provider "aws" {
    region = "us-east-2"
}

# Auto Scaling Group（ASG） 内のインスタンスの起動設定（起動テンプレートを使うのが一般的 https://docs.aws.amazon.com/ja_jp/autoscaling/ec2/userguide/launch-templates.html）
resource "aws_launch_configuration" "example" {
    image_id = "ami-0fb653ca2d3203ac1"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.instance.id]

    # 最初のインスタンス起動時にのみ実行されるスクリプト
    user_data = <<-EOF
        #!/bin/bash
        echo "Hello, World" > index.html
        nohup busybox httpd -f -p ${var.server_port} &
    EOF

    # ASGからの参照を失わないように変更を適用する
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "example" {
    launch_configuration = aws_launch_configuration.example.name

    # EC2インスタンスのデプロイ先のVPCサブネット群（ハードコードせずにデータソースから値を動的に取得）
    vpc_zone_identifier = data.aws_subnets.default.ids

    min_size = 0
    max_size = 0

    tag {
        key = "Name"
        value = "terraform-asg-example"
        propagate_at_launch = true
    }
}

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

resource "aws_security_group" "instance" {
    name = "terraform-example-instance"

    # Webサーバへのアクセスを許可
    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # アクセス可能なIPアドレス範囲
    }
}

variable "server_port" {
    description = "The port the server will use for HTTP requests"
    type = number
    default = 8080
}