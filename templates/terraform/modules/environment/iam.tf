
#
# Kubernetes admin role

# Create KubernetesAdmin role for aws-iam-authenticator
resource "aws_iam_role" "kubernetes_admin_role" {
  name               = "${var.project}-kubernetes-admin-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.assumerole_root_policy.json
  description        = "Kubernetes administrator role (for AWS EKS auth)"
}

# Trust relationship to limit access to the k8s admin serviceaccount
data "aws_iam_policy_document" "assumerole_root_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }
  }
}
