variable "project" {
  description = "The name of the project, mostly for tagging"
}

variable "environment" {
  description = "The environment (dev/staging/prod)"
}

variable "region" {
  description = "The AWS region"
}

variable "allowed_account_ids" {
  description = "The IDs of AWS accounts for this project, to protect against mistakenly applying to the wrong env"
  type        = list(string)
}

variable "ecr_repositories" {
  description = "List of ECR repository names to create"
  type        = list(string)
}

variable "eks_cluster_version" {
  description = "EKS cluster version number to use. Incrementing this will start a cluster upgrade"
}

variable "eks_worker_instance_type" {
  description = "Instance type for the EKS workers"
}

variable "eks_worker_asg_min_size" {
  description = "Minimum number of instances for the EKS ASG"
}

variable "eks_worker_asg_max_size" {
  description = "Maximum number of instances for the EKS ASG"
}

variable "eks_worker_ami" {
  description = "The (EKS-optimized) AMI for EKS worker instances"
}

variable "s3_hosting_buckets" {
  description = "S3 hosting buckets"
  type = set(string)
}

variable "domain_name" {
  description = "Domain to create a R53 Zone and ACM Cert for"
  type = string
}

variable "db_instance_class" {
  description = "The AWS instance class of the db"
}

variable "db_storage_gb" {
  description = "The amount of storage to allocate for the db, in GB"
}

variable "vpc_use_single_nat_gateway" {
  description = "Use single nat-gateway instead of nat-gateway per subnet"
  type        = bool
  default     = true
}
