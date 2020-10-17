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

variable "random_seed" {
  description = "A randomly generated string to prevent collisions of resource names - should be unique within an AWS account"
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

variable "hosted_domains" {
  description = "Domains to host content for using S3 and Cloudfront. Requires a domain which will be the bucket name and the domain for the certificate, and optional aliases which will have records created for them and will be SubjectAltNames for the certificate. Only a single bucket and CF Distribution will be created per domain."
  type = list(object({
    domain          = string
    aliases         = list(string)
    signed_urls     = bool
    trusted_signers = list(string)
    cors_origins    = list(string)
  }))
}

variable "domain_name" {
  description = "Domain to create a R53 Zone and ACM Cert for"
  type        = string
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

variable "database" {
  default     = "postgres"
  description = "Which database engine to use, currently supports postgres or mysql"
}


variable "logging_type" {
  description = "Which application logging mechanism to use (cloudwatch, kibana)"
  type        = string
  default     = "cloudwatch"

  validation {
    condition = (
      var.logging_type == "cloudwatch" || var.logging_type == "kibana"
    )
    error_message = "Invalid value. Valid values are cloudwatch or kibana."
  }
}

# The following have default values specified in case logging_type is not set to "kibana", in which case they are not necessary.
variable "logging_es_version" {
  description = "The version of elasticsearch to use"
  default     = "7.7"
}

variable "logging_create_service_role" {
  description = "Set this to false if you already have an existing Elasticsearch cluster in this AWS account"
  type        = bool
  default     = true
}

variable "logging_az_count" {
  description = "The number of availability zones to use for the cluster. More is more higly available but requires more instances, which increases cost"
  type        = number
  default     = 1
}

variable "logging_es_instance_type" {
  description = "Instance type for nodes"
  default     = "m3.medium.elasticsearch"
}

variable "logging_es_instance_count" {
  description = "Number of nodes in the cluster. Must be a multiple of the number of availability zones"
  type        = number
  default     = 1
}

variable "logging_volume_size_in_gb" {
  description = "Size of EBS volume (in GB) to attach to *each* of the nodes in the cluster. The maximum size is limited by the size of the instance"
  type        = number
  default     = 10
}

variable "enable_cluster_logging" {
  description = "If enabled, sends the logs from the elasticsearch cluster to Cloudwatch"
  type        = bool
  default     = false
}

variable "sendgrid_enabled" {
  description = "If enabled, creates route53 entries for domain authentication"
  type        = bool
}

variable "sendgrid_api_key_secret_name" {
  description = "AWS secret manager's secret name storing the sendgrid api key"
  type        = string
}

variable "roles" {
  type = list(object({
    name         = string
    aws_policy   = string
    k8s_policies = list(map(list(string)))
    k8s_groups   = list(string)
  }))
  description = "Role list with policies"
}

variable "user_role_mapping" {
  type = list(object({
    name = string
    roles = list(object({
      name         = string
      environments = list(string)
    }))
  }))
  description = "User-Roles mapping with environment"
}

variable "ci_users" {
  description = "CI Users"
  type        = list(string)
}
