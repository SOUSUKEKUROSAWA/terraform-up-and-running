# 必要なロードバランサのホスト名
output "service_endpoint" {
    value = module.simple_webapp.service_endpoint
    description = "The Kubernetes Service endpoint"
}