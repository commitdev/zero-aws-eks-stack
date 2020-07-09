variable "project" {
  description = "The name of the project, mostly for tagging"
}

variable "environment" {
  description = "The environment (development/staging/production)"
}

variable "region" {
  description = "The AWS region"
}

variable "kubernetes_cluster_name" {
  description = "Kubernetes cluster name used to associate with subnets for auto LB placement"
}

variable "single_nat_gateway" {
  description = "Use single nat-gateway instead of nat-gateway per subnet"
  type        = bool
}
