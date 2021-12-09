locals {
    # Standardize the kubernetes role name
    k8s_role_name_format = "%s-kubernetes-%s-%s" # <project_name>-kubernetes-<role_name>-<environment>

    # Roles for each defined user, plus an admin user
    comfigmap_roles = concat(
    # Always create this admin user, as we use it by default in some of the scripts
    [{
      rolearn  = "arn:aws:iam::${var.allowed_account_ids[0]}:role/${format(local.k8s_role_name_format, var.project_name, "admin", var.environment)}"
      username = format(local.k8s_role_name_format, var.project_name, "admin", var.environment)
      groups   = ["system:masters"]
    }],
    [
      for r in var.k8s_role_mapping : {
        rolearn  = "arn:aws:iam::${var.allowed_account_ids[0]}:role/${format(local.k8s_role_name_format, var.project_name, r.name, var.environment)}"
        username = format(local.k8s_role_name_format, var.project_name, r.name, var.environment)
        groups   = r.k8s_groups
      }
    ]
  )

  # Role required by eks node group worker instances
  worker_roles = [
    for node_group in aws_eks_node_group.cluster :
    {
      rolearn  = node_group.node_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
          "system:bootstrappers",
          "system:nodes",
        ]
    }
  ]
}

# Look up the cluster node group to get the worker roles
data "aws_eks_node_groups" "cluster" {
  cluster_name = var.cluster_name
}

data "aws_eks_node_group" "cluster" {
  count = count(data.aws_eks_node_groups.cluster.names)
  cluster_name    = var.cluster_name
  node_group_name = data.aws_eks_node_groups.cluster.names[count.index]
}

# Create the configmap
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
    labels = {
        "app.kubernetes.io/managed-by" = "Terraform"
        "terraform.io/module" = "terraform-aws-modules.eks.aws"
      }
  }

  data = {
    mapRoles = yamlencode(
      distinct(concat(
        local.configmap_roles,
        var.map_roles,
      ))
    )
  }
}

# Create assumeable roles for each user type
resource "aws_iam_role" "access_assumerole" {
  for_each = local.configmap_roles

  name               = each.value.username
  assume_role_policy = data.aws_iam_policy_document.access_assumerole_root_policy.json
  description        = "Assumable role for Kubernetes auth"
}

# Trust relationship to limit access to the assumable roles to the current aws account or other accounts passed in
data "aws_iam_policy_document" "access_assumerole_root_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = length(var.assumerole_account_ids) == 0 ? local.allowed_account_ids : var.assumerole_account_ids
    }
  }
}

# Create Kubernetes cluster role and group binding for API access
resource "kubernetes_cluster_role" "access_role" {
  for_each = var.k8s_role_mapping

  metadata {
    name = format(local.k8s_role_name_format, var.project_name, each.value.name, var.environment)
  }

  dynamic "rule" {
    for_each = each.value.k8s_policies
    content {
      verbs      = rule.value.verbs
      api_groups = rule.value.api_groups
      resources  = rule.value.resources
    }
  }
}

resource "kubernetes_cluster_role_binding" "access_role" {
  for_each = kubernetes_cluster_role.access_role

  metadata {
    name = kubernetes_cluster_role.access_role[each.key].metadata.0.name
  }
  subject {
    kind = "Group"
    name = kubernetes_cluster_role.access_role[each.key].metadata.0.name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.access_role[each.key].metadata.0.name
  }
}
