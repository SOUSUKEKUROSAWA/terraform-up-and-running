module "simple_webapp" {
    source = "github.com/SOUSUKEKUROSAWA/terraform-up-and-running-module//services/kubernetes-app?ref=v0.0.13"

    name = "simple-webapp"
    image = "training/webapp"
    replicas = 2
    container_port = 5000

    environment_variables = {
        PROVIDER = "Terraform" # レスポンスが「Hello <PROVIDER>!」に変更される
    }
}