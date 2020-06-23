# Set up the terraform provider
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.11"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "12.1.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  subnets         = var.private_subnets
  vpc_id          = var.vpc_id
  enable_irsa     = true

  worker_groups = [
    {
      instance_type         = var.worker_instance_type
      asg_min_size          = var.worker_asg_min_size
      asg_desired_capacity  = var.worker_asg_min_size
      asg_max_size          = var.worker_asg_max_size
      ami_id                = var.worker_ami
      tags = [
        {
          key                 = "environment"
          value               = var.environment
          propagate_at_launch = true
        },
        {
          key                 = "k8s.io/cluster-autoscaler/enabled"
          propagate_at_launch = "false"
          value               = "true"
        },
        {
          key                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
          propagate_at_launch = "false"
          value               = "owned"
        }
      ]

    },
  ]

  map_roles = [
    {
      rolearn  = "arn:aws:iam::${var.iam_account_id}:role/<% .Name %>-kubernetes-admin-${var.environment}"
      username = "<% .Name %>-kubernetes-admin"
      groups   = ["system:masters"]
    },
  ]
  cluster_iam_role_name = "k8s-${var.cluster_name}-cluster"
  workers_role_name = "k8s-${var.cluster_name}-workers"

  # Unfortunately fluentd doesn't yet support oidc auth so we need to grant it to the worker nodes
  workers_additional_policies = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"]

  write_kubeconfig      = false

  tags = {
    environment = var.environment
  }
}
