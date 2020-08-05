terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket         = "<% .Name %>-production-terraform-state"
    key            = "infrastructure/terraform/environments/production/main"
    encrypt        = true
    region         = "<% index .Params `region` %>"
    dynamodb_table = "<% .Name %>-production-terraform-state-locks"
  }
}

# Instantiate the production environment
module "production" {
  source      = "../../modules/environment"
  environment = "prod"

  # Project configuration
  project             = "<% .Name %>"
  region              = "<% index .Params `region` %>"
  allowed_account_ids = ["<% index .Params `accountId` %>"]

  # ECR configuration
  ecr_repositories = [] # Should be created by the staging environment

  # EKS configuration
  eks_cluster_version      = "1.16"
  eks_worker_instance_type = "t3.medium"
  eks_worker_asg_min_size  = 2
  eks_worker_asg_max_size  = 4

  # EKS-Optimized AMI for your region: https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html
  # https://us-east-1.console.aws.amazon.com/systems-manager/parameters/%252Faws%252Fservice%252Feks%252Foptimized-ami%252F1.15%252Famazon-linux-2%252Frecommended%252Fimage_id/description?region=us-east-1
  eks_worker_ami = "<% index .Params `eksWorkerAMI` %>"

  # Hosting configuration
  s3_hosting_buckets = [
    "<% index .Params `productionFrontendSubdomain` %><% index .Params `productionHostRoot` %>"
  ]
  domain_name = "<% index .Params `productionHostRoot` %>"

  # DB configuration
  db_instance_class = "db.t3.small"
  db_storage_gb = 100

}
