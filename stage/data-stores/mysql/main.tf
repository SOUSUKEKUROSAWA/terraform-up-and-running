module "mysql" {
    source = "github.com/SOUSUKEKUROSAWA/terraform-up-and-running-module//data-stores/mysql?ref=v0.0.12"

    db_name = "stage_db"
    db_username = local.db_credentials.username
    db_password = local.db_credentials.password
}