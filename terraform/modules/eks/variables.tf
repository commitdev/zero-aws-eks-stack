variable "project" {
  description = "Name of the project"
}

variable "environment" {
  description = "The environment (development/staging/production)"
}

variable "cluster_name" {
  description = "Name to be given to the EKS cluster"
}

variable "cluster_version" {
  description = "EKS cluster version number to use. Incrementing this will start a cluster upgrade"
}

variable "private_subnets" {
  description = "VPC subnets for the EKS cluster"
  # type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for EKS cluster"
}

variable "worker_instance_type" {
  description = "Instance type for the EKS workers"
}

variable "worker_asg_min_size" {
  description = "Minimum number of instances for the EKS ASG"
}

variable "worker_asg_max_size" {
  description = "Maximum number of instances for the EKS ASG"
}

variable "worker_ami" {
  description = "The (EKS-optimized) AMI for EKS worker instances"
}

variable "iam_account_id" {
  description = "Account ID of the current IAM user"
}

