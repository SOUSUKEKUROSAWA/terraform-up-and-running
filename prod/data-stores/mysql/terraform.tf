terraform {
    backend "s3" {
        key = "prod/data-stores/mysql/terraform.tfstate"
    }
}