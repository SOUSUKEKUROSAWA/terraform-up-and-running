terraform {
    backend "s3" {
        key = "example/asg/terraform.tfstate"
    }
}