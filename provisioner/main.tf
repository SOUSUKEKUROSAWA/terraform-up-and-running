resource "aws_instance" "local_exec" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"

    provisioner "local-exec" {
        # Apply時にローカルOSの詳細を表示
        command = "echo \"Hello, World from $(uname -smp)\""
    }
}

resource "aws_instance" "remote_exec" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"

    # SSHのデフォルトポートをあける
    vpc_security_group_ids = [aws_security_group.instance.id]

    # パブリックキーを紐づけ
    key_name = aws_key_pair.generated_key.key_name

    provisioner "remote-exec" {
        inline = ["echo \"Hello, World from $(uname -smp)\""]
    }

    # remote-exec する際にどのようにEC2に接続するのかを指示
    connection {
        type = "ssh"
        host = self.public_ip
        user = "ubuntu"
        private_key = tls_private_key.example.private_key_pem
    }
}

# SSHのデフォルトポートへのインバウンド接続を許可
resource "aws_security_group" "instance" {
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"

        # 実世界では，信頼できるIPのみに接続を許可するようにすべき
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# 実世界では，SSH鍵はTerraformとは別で管理すべき
# -- 通常は，自分のコンピュータ上でSSH鍵ペアを生成し，
# -- パブリックキーをAWSへアップロード，
# -- プライベートキーはTerraformがアクセスできるセキュアな場所に保存する
resource "tls_private_key" "example" {
    algorithm = "RSA"
    rsa_bits = 4096
}

# パブリックキーをAWSにアップロード
resource "aws_key_pair" "generated_key" {
    public_key = tls_private_key.example.public_key_openssh
}