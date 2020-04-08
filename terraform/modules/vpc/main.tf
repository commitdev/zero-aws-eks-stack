module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "10.0.0"

  name = "${var.project}-${var.environment}-vpc"
  cidr = "10.11.0.0/16"
# @TODO - Change back to 10.10
  azs              = ["${var.region}a", "${var.region}b"] # Most regions have 3+ azs
  private_subnets  = ["10.11.32.0/19", "10.11.64.0/19"]
  public_subnets   = ["10.11.1.0/24",  "10.11.2.0/24"]
  database_subnets = ["10.11.10.0/24", "10.11.11.0/24"]

  # Allow kubernetes ALB ingress controller to auto-detect
  private_subnet_tags = {
    "kubernetes.io/cluster/${var.kubernetes_cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"      = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.kubernetes_cluster_name}" = "owned"
    "kubernetes.io/role/elb"               = "1"
  }

  enable_nat_gateway   = true
  enable_vpn_gateway   = false
  enable_dns_hostnames = true

  create_database_subnet_group       = true
  create_database_subnet_route_table = true

  tags = {
    environment = var.environment
  }

  vpc_tags = {
    "kubernetes.io/cluster/${var.kubernetes_cluster_name}" = "shared"
  }
}
