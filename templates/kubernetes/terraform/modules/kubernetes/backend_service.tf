data "aws_secretsmanager_secret" "cf_keypair" {
  name = "${var.project}_cf_keypair"
}

data "aws_secretsmanager_secret_version" "cf_keypair" {
  secret_id = data.aws_secretsmanager_secret.cf_keypair.id
}

locals {
  cf_keypair_json = var.cf_signing_enabled ? jsondecode(data.aws_secretsmanager_secret_version.cf_keypair.secret_string) : ""
}

resource "kubernetes_secret" "cf_keypair" {
  count = var.cf_signing_enabled ? 1 : 0

  metadata {
    name = "cf-keypair"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  data = {
    keypair_id = local.cf_keypair_json["keypair_id"]
    private_key = local.cf_keypair_json["private_key"]
  }

  type = "Opaque"
}
