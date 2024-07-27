module "mysql_primary" {
    source = "github.com/SOUSUKEKUROSAWA/terraform-up-and-running-module//data-stores/mysql?ref=v0.0.12"

    providers = {
        aws = aws.primary # ここのawsというプロバイダのLOCAL_NAMEがモジュールのプロバイダのローカル名と一致している必要がある
    }

    db_name = "prod_db"
    db_username = local.db_credentials.username
    db_password = local.db_credentials.password

    # レプリケーションをサポートするために有効にする
    backup_retention_period = 1
}

module "mysql_replica" {
    source = "github.com/SOUSUKEKUROSAWA/terraform-up-and-running-module//data-stores/mysql?ref=v0.0.12"

    providers = {
        aws = aws.replica
    }

    # プライマリのレプリカとして設定
    replicate_source_db = module.mysql_primary.arn
}