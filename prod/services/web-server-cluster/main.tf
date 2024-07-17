module "webserver_cluster" {
    # タグでバージョン指定してモジュールのコードをダウンロード
    source = "github.com/SOUSUKEKUROSAWA/terraform-up-and-running-module//services/web-server-cluster?ref=v0.0.5"

    cluster_name = "webservers-prod"
    db_remote_state_bucket = "terraform-up-and-running-backend"
    db_remote_state_key = "prod/data-stores/mysql/terraform.tfstate"
    instance_type = "t2.micro" # m4.large などを使いたいが，練習用なので低コストなインスタンスタイプを選択
    min_size = 2
    max_size = 10

    enable_autoscaling = true

    custom_tags = {
        Owner = "team-foo"
        DeployedBy = "terraform"
    }
}