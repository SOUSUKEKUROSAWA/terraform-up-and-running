resource "aws_lb" "example" {
    name = var.cluster_name
    load_balancer_type = "application"

    # ALBは別々のサブネット（データセンタ）に複数台動作していて，自動的にスケールアップ／ダウンする
    # 本来，ALBはパブリックサブネット，EC2はプライベートサブネットに分けてデプロイするのが一般的
    subnets = data.aws_subnets.default.ids

    security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.example.arn
    port = local.http_port
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
    name = var.cluster_name
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
    name = "${var.cluster_name}-alb"
}

# モジュールの柔軟性を高めるためにASGとは別リソースで定義
# -- SGのリソース内にインラインブロックとして定義するとモジュール利用側で aws_security_group_rule を追加できなくなってしまう
# -- ex. Stage環境でのみインバウンドを許可するポートを増やしたい場合など
resource "aws_security_group_rule" "allow_http_inbound" {
    type = "ingress"
    security_group_id = aws_security_group.alb.id

    from_port = local.http_port
    to_port = local.http_port
    protocol = local.tcp_protocol # TCPはトランスポート層のプロトコルで，HTTPはこの上で動作する
    cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_http_outbound" {
    type = "egress"
    security_group_id = aws_security_group.alb.id

    # EC2クラスタに対するヘルスチェックのため，全開放
    from_port = local.any_port
    to_port = local.any_port
    protocol = local.any_protocol
    cidr_blocks = local.all_ips
}

# Auto Scaling Group（ASG） 内のインスタンスの起動設定（起動テンプレートを使うのが一般的 https://docs.aws.amazon.com/ja_jp/autoscaling/ec2/userguide/launch-templates.html）
resource "aws_launch_configuration" "example" {
    image_id = "ami-0fb653ca2d3203ac1"
    instance_type = var.instance_type
    security_groups = [aws_security_group.instance.id]

    # 最初のインスタンス起動時にのみ実行されるスクリプト
    user_data = templatefile("${path.module}/user-data.sh", {
        server_port = var.server_port
        # terraform_remote_stateはDBがデプロイされた状態でないと使えないので注意
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

    min_size = var.min_size
    max_size = var.max_size

    tag {
        key = "Name"
        value = var.cluster_name
        propagate_at_launch = true
    }
}

resource "aws_security_group" "instance" {
    name = "${var.cluster_name}-instance"
}

# モジュールの柔軟性を高めるためにASGとは別リソースで定義
# -- SGのリソース内にインラインブロックとして定義するとモジュール利用側で aws_security_group_rule を追加できなくなってしまう
# -- ex. Stage環境でのみインバウンドを許可するポートを増やしたい場合など
resource "aws_security_group_rule" "allow_server_http_inbound" {
    type = "ingress"
    security_group_id = aws_security_group.instance.id

    # Webサーバへのアクセスを許可
    from_port = var.server_port
    to_port = var.server_port
    protocol = local.tcp_protocol
    cidr_blocks = local.all_ips # アクセス可能なIPアドレス範囲
}