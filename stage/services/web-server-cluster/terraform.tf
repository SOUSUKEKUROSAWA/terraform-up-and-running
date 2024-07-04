terraform {
    backend "s3" {
        key = "stage/services/web-server-cluster/terraform.tfstate"
    }
}