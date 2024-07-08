terraform {
    backend "s3" {
        key = "prod/services/web-server-cluster/terraform.tfstate"
    }
}