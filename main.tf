provider "aws" {
    region = "us-east-2"
}

resource "aws_instance" "example" {
    ami = "ami-0fb653ca2d3203ac1"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.instance.id]

    # 最初のインスタンス起動時にのみ実行されるスクリプト
    user_data = <<-EOF
        #!/bin/bash
        echo "Hello, World" > index.html
        nohup busybox httpd -f -p ${var.server_port} &
    EOF

    # ユーザーデータの変更を適用するために，毎回インスタンスをリプレイスする
    user_data_replace_on_change = true

    tags = {
        Name = "terraform-example"
    }
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

# Apply時に出力して，IPを探す手間を省く
output "public_ip" {
    value = aws_instance.example.public_ip
    description = "The public IP address of the web server"
}