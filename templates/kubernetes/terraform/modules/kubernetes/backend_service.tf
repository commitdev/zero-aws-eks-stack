data "aws_secretsmanager_secret" "by-name" {
  name = "<% .Name %>_cf_keypair"
}

data "aws_secretsmanager_secret_version" "cf_keypair" {
  secret_id = data.aws_secretsmanager_secret.<% .Name %>_cf_keypair.id
}

locals {
  cf_keypair_json = jsondecode(data.aws_secretsmanager_secret_version.cf_keypair.secret_string)
}

resource "kubernetes_secret" "cf_keypair" {
  metadata {
    name = "cf-keypair"
  }

  data = {
    keypair_id = local.cf_keypair_json["keypair_id"]
    secret_key = local.cf_keypair_json["private_key"]
  }

  type = "Opaque"
}
