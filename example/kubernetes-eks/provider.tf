provider "aws" {
    region = "us-east-2"
}

provider "kubernetes" {
    host = module.eks_cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority[0].data)
    token = data.aws_eks_cluster_auth.cluster.token
}