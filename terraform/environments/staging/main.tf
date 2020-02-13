terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket         = "<% .Name %>-staging-terraform-state"
    key            = "infrastructure/terraform/environments/staging/main"
    encrypt        = true
    region         = "us-west-2"
    dynamodb_table = "<% .Name %>-staging-terraform-state-locks"
  }
}

# Instantiate the staging environment
module "staging" {
  source      = "../../modules/environment"
  environment = "staging"

  # Project configuration
  project             = "<% .Name %>"
  region              = "us-west-2"
  allowed_account_ids = ["694969179370"]
  # ECR configuration
  ecr_repositories = [ "gql-server"
  ]

  # EKS configuration
  eks_worker_instance_type = "t2.small"
  eks_worker_asg_min_size  = 2
  eks_worker_asg_max_size  = 6

  # EKS-Optimized AMI for your region: https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html
  # https://us-east-1.console.aws.amazon.com/systems-manager/parameters/%252Faws%252Fservice%252Feks%252Foptimized-ami%252F1.14%252Famazon-linux-2%252Frecommended%252Fimage_id/description?region=us-east-1
  eks_worker_ami = "ami-07be7092831897fd6"

  # Hosting configuration
  s3_hosting_buckets = [
    "jobs.<% .Name %>-staging.com",
    "storybook.<% .Name %>-staging.com"
  ]
  s3_hosting_cert_domain = "<% .Name %>-staging.com"

  # DB configuration
  db_instance_class = "db.t3.small"
  db_storage_gb = 20
}
