module "webserver_cluster" {
    # タグでバージョン指定してモジュールのコードをダウンロード
    source = "github.com/SOUSUKEKUROSAWA/terraform-up-and-running-module//services/web-server-cluster?ref=v0.0.1"

    cluster_name = "webservers-prod"
    db_remote_state_bucket = "terraform-up-and-running-backend"
    db_remote_state_key = "prod/data-stores/mysql/terraform.tfstate"
    instance_type = "t2.micro" # m4.large などを使いたいが，練習用なので低コストなインスタンスタイプを選択
    min_size = 2
    max_size = 10
}

# 時間に応じてキャパシティを変化させるスケジュールを別途追加（Stage環境では不要）
resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
    scheduled_action_name = "scale-out-during-business-hours"
    min_size = 2
    max_size = 10
    desired_capacity = 10
    recurrence = "0 9 * * *"
    autoscaling_group_name = module.webserver_cluster.asg_name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
    scheduled_action_name = "scale-in-at-night"
    min_size = 2
    max_size = 10
    desired_capacity = 2
    recurrence = "0 17 * * *"
    autoscaling_group_name = module.webserver_cluster.asg_name
}