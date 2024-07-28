module "asg" {
    source = "github.com/SOUSUKEKUROSAWA/terraform-up-and-running-module//cluster/asg-rolling-deploy?ref=v0.0.18"

    cluster_name = "webservers-example"
    ami = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"

    min_size = 1
    max_size = 1
    enable_autoscaling = false

    subnet_ids = data.aws_subnets.default.ids
}