terraform {
    backend "s3" {
        key = "stage/data-stores/mysql/terraform.tfstate"
    }
}