terraform {
  required_version = ">= 0.13"
  backend "s3" {
    bucket         = "<% .Name %>-stage-terraform-state"
    key            = "infrastructure/terraform/environments/stage/main"
    encrypt        = true
    region         = "<% index .Params `region` %>"
    dynamodb_table = "<% .Name %>-stage-terraform-state-locks"
  }
}

provider "aws" {
  region              = "<% index .Params `region` %>"
  allowed_account_ids = ["<% index .Params `accountId` %>"]
}

# Instantiate the staging environment
module "stage" {
  source      = "../../modules/environment"
  environment = "stage"

  # Project configuration
  project             = "<% .Name %>"
  region              = "<% index .Params `region` %>"
  allowed_account_ids = ["<% index .Params `accountId` %>"]
  random_seed         = "<% index .Params `randomSeed` %>"

  # ECR configuration
  ecr_repositories = [ "<% .Name %>" ]

  # EKS configuration
  eks_cluster_version      = "1.17"
  eks_worker_instance_type = "t3.medium"
  eks_worker_asg_min_size  = 1
  eks_worker_asg_max_size  = 3

  # EKS-Optimized AMI for your region: https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html
  # https://<% index .Params `region` %>.console.aws.amazon.com/systems-manager/parameters/%252Faws%252Fservice%252Feks%252Foptimized-ami%252F1.17%252Famazon-linux-2%252Frecommended%252Fimage_id/description?region=<% index .Params `region` %>
  eks_worker_ami = "<% index .Params `eksWorkerAMI` %>"

  # Hosting configuration
  s3_hosting_buckets = [
    "<% index .Params `stagingHostRoot` %>",
    "<% index .Params `stagingFrontendSubdomain` %><% index .Params `stagingHostRoot` %>",
  ]
  domain_name = "<% index .Params `stagingHostRoot` %>"
  cf_signed_downloads = <% if eq (index .Params `fileUploads`) "yes" %>true<% else %>false<% end %>

  # This will save some money as there a cost associated to each NAT gateway, but if the AZ with the gateway
  # goes down, nothing in the private subnets will be able to reach the internet. Not recommended for production.
  vpc_use_single_nat_gateway = true

  # DB configuration
  database = "<% index .Params `database` %>"
  db_instance_class = "db.t3.small"
  db_storage_gb = 20

  # Logging configuration
  logging_type = "<% index .Params `loggingType` %>"
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_es_version = "7.7"
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_create_service_role = true # Set this to false if you need to create more than one ES cluster in an AWS account
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_az_count = "1"
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_es_instance_type = "t2.medium.elasticsearch"
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_es_instance_count = "1" # Must be a mulitple of the az count
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_volume_size_in_gb = "10" # Maximum value is limited by the instance type
  # See https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/aes-limits.html

  sendgrid_enabled = <%if eq (index .Params `sendgridApiKey`) "" %>false<% else %>true<% end %>
  sendgrid_api_key_secret_name = "<% .Name %>-sendgrid-<% index .Params `randomSeed` %>"

  # IAM roles and users
  iam_roles = [
    ["developer", data.aws_iam_policy_document.developer_access.json],
    ["operator",  data.aws_iam_policy_document.developer_access.json],
  ]
  iam_users = [
    ["dev1",      ["developer"]],
    ["devops1",   ["developer", "operator"]],
    ["operator1", ["operator"]],
  ]
}
