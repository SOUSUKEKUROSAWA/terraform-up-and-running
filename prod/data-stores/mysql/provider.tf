provider "aws" {
    region = "us-east-2"
    alias = "primary"
}

provider "aws" {
    region = "us-west-1"
    alias = "replica"
}