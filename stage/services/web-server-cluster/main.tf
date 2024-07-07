resource "aws_lb" "example" {
    name = "terraform-asg-example"
    load_balancer_type = "application"

    # ALBは別々のサブネット（データセンタ）に複数台動作していて，自動的にスケールアップ／ダウンする
    # 本来，ALBはパブリックサブネット，EC2はプライベートサブネットに分けてデプロイするのが一般的
    subnets = data.aws_subnets.default.ids

    security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.example.arn
    port = 80
    protocol = "HTTP"

    # リスナールールに一致しないリクエストに対するレスポンス
    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code = 404
        }
    }
}

# リスナに対するアクセスを受け取り，特定のパスやホスト名に一致したリクエストを，指定したターゲットグループに送信する
resource "aws_lb_listener_rule" "asg" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100

    condition {
        path_pattern {
            values = ["*"]
        }
    }

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.asg.arn
    }
}

# ロードバランサからリクエストを受け取るサーバ群
# サーバに対するヘルスチェックも行い，チェックをパスしたノードにリクエストを送る
resource "aws_lb_target_group" "asg" {
    name = "terraform-asg-example"
    port = var.server_port
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id

    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200" # レスポンスが200 OKであるかをチェック
        interval = 15
        timeout = 3
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}

resource "aws_security_group" "alb" {
    name = "terraform-example-alb"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp" # TCPはトランスポート層のプロトコルで，HTTPはこの上で動作する
        cidr_blocks = ["0.0.0.0/0"]
    }

    # EC2クラスタに対するヘルスチェックのため，全開放
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Auto Scaling Group（ASG） 内のインスタンスの起動設定（起動テンプレートを使うのが一般的 https://docs.aws.amazon.com/ja_jp/autoscaling/ec2/userguide/launch-templates.html）
resource "aws_launch_configuration" "example" {
    image_id = "ami-0fb653ca2d3203ac1"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.instance.id]

    # 最初のインスタンス起動時にのみ実行されるスクリプト
    user_data = templatefile("user-data.sh", {
        server_port = var.server_port
        db_address = data.terraform_remote_state.db.outputs.address
        db_port = data.terraform_remote_state.db.outputs.port
    })

    # ASGからの参照を失わないように変更を適用する
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "example" {
    launch_configuration = aws_launch_configuration.example.name

    # EC2インスタンスのデプロイ先のVPCサブネット群（ハードコードせずにデータソースから値を動的に取得）
    vpc_zone_identifier = data.aws_subnets.default.ids

    # ASG内のサーバ群をLBのターゲットグループに動的にアタッチ
    target_group_arns = [aws_lb_target_group.asg.arn]

    # LBのターゲットグループのヘルスチェック結果を使い，unhealthyな場合は自動でインスタンスを置き換える
    health_check_type = "ELB"

    min_size = 2
    max_size = 10

    tag {
        key = "Name"
        value = "terraform-asg-example"
        propagate_at_launch = true
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