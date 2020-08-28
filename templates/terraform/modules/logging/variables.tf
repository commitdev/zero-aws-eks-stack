variable "project" {
  description = "The name of the project, mostly for tagging"
}

variable "environment" {
  description = "The environment (dev/staging/prod)"
}

variable "vpc_id" {
  description = "ID of the VPC to create this cluster in"
}

variable "elasticsearch_version" {
  description = "Version of elasticsearch to use"
}

variable "security_groups" {
  description = "Security groups to allow access from"
  type        = list(string)
}

variable "subnet_ids" {
  description = "IDs of the subnets to put nodes in. The number of subnets here controls the number of nodes in the cluster, which must be a multiple of this number"
  type        = list(string)
}

variable "instance_type" {
  description = "Instance type for nodes"

  validation {
    condition     = can(regex("^[[:alpha:]][[:digit:]]\\..*\\.elasticsearch$", var.instance_type))
    error_message = "The instance_type variable must contain a valid elasticsearch instance type."
  }
}

variable "create_service_role" {
  description = "Set this to false if you already have an existing Elasticsearch cluster in this AWS account"
  type        = bool
}

variable "instance_count" {
  description = "Number of nodes in the cluster. Must be a multiple of the number of"
  type        = number
}

variable "ebs_volume_size_in_gb" {
  description = "Size of EBS volume (in GB) to attach to *each* of the nodes in the cluster. The maximum size is limited by the size of the instance"
  type        = number
}

variable "enable_cluster_logging" {
  description = "If enabled, sends the logs from the elasticsearch cluster to Cloudwatch"
  type        = bool
  default     = false
}
