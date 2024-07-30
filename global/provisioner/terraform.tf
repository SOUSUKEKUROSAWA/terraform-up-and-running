terraform {
    backend "s3" {
        key = "global/provisioner/terraform.tfstate"
    }
}