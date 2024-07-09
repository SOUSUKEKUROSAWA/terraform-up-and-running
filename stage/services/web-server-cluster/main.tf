module "webserver_cluster" {
    # タグでバージョン指定してモジュールのコードをダウンロード
    source = "github.com/SOUSUKEKUROSAWA/terraform-up-and-running-module//services/web-server-cluster?ref=v0.0.1"

    cluster_name = "webservers-stage"
    db_remote_state_bucket = "terraform-up-and-running-backend"
    db_remote_state_key = "stage/data-stores/mysql/terraform.tfstate"
    instance_type = "t2.micro"
    min_size = 2
    max_size = 2
}

# テスト用にStage環境のみ追加でポートをあける
# -- モジュール側でSGのingressルールがリソースとして定義されているからこれが可能
# -- もし，SGのインラインブロックとして一つでもingressルールが定義されていると，このコードは動作しなくなってしまうので注意
resource "aws_security_group_rule" "allow_testing_inbound" {
    type = "ingress"
    security_group_id = module.webserver_cluster.alb_security_group_id

    from_port = 12345
    to_port = 12345
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}