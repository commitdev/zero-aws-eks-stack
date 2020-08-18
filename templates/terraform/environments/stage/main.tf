terraform {
  required_version = ">= 0.13"
  backend "s3" {
    bucket         = "<% .Name %>-stage-terraform-state"
    key            = "infrastructure/terraform/environments/staging/main"
    encrypt        = true
    region         = "<% index .Params `region` %>"
    dynamodb_table = "<% .Name %>-stage-terraform-state-locks"
  }
}

# Instantiate the staging environment
module "stage" {
  source      = "../../modules/environment"
  environment = "stage"

  # Project configuration
  project             = "<% .Name %>"
  region              = "<% index .Params `region` %>"
  allowed_account_ids = ["<% index .Params `accountId` %>"]
  # ECR configuration
  ecr_repositories = [ "<% .Name %>" ]

  # EKS configuration
  eks_cluster_version      = "1.16"
  eks_worker_instance_type = "t3.medium"
  eks_worker_asg_min_size  = 1
  eks_worker_asg_max_size  = 3

  # EKS-Optimized AMI for your region: https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html
  # https://us-east-1.console.aws.amazon.com/systems-manager/parameters/%252Faws%252Fservice%252Feks%252Foptimized-ami%252F1.15%252Famazon-linux-2%252Frecommended%252Fimage_id/description?region=us-east-1
  eks_worker_ami = "<% index .Params `eksWorkerAMI` %>"

  # Hosting configuration
  s3_hosting_buckets = [
    "<% index .Params `stagingHostRoot` %>",
    "<% index .Params `stagingFrontendSubdomain` %><% index .Params `stagingHostRoot` %>",
  ]
  domain_name = "<% index .Params `stagingHostRoot` %>"

  vpc_use_single_nat_gateway = true

  # DB configuration
  database = "<% index .Params `database` %>"
  db_instance_class = "db.t3.small"
  db_storage_gb = 20
}
