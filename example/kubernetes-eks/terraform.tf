terraform {
    backend "s3" {
        key = "example/kubernetes-eks/terraform.tfstate"
    }
}