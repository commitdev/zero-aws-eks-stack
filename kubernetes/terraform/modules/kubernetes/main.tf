
module "monitoring" {
  source             = "./monitoring"
  environment        = var.environment
  region             = var.region
  cluster_name       = var.cluster_name
}

module "ingress" {
  source                     = "./ingress"
  environment                = var.environment
  region                     = var.region
  load_balancer_ssl_cert_arn = ""
}
