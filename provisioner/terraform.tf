terraform {
    backend "s3" {
        key = "provisioner/terraform.tfstate"
    }
}