terraform {
    backend "s3" {
        key = "example/kubernetes-local/terraform.tfstate"
    }
}