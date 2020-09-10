data "aws_secretsmanager_secret_version" "cf_keypair" {
  secret_id = data.aws_secretsmanager_secret.cf_keypair.id
  value = jsondecode(data.aws_secretsmanager_secret_version.cf_keypair.secret_string)
}

resource "kubernetes_secret" "cf_keypair" {
  metadata {
    name = "cf-keypair"
  }

  data = {
    keypair_id = aws_secretsmanager_secret_version.cf_keypair_secret.value["keypair_id"]
    secret_key = aws_secretsmanager_secret_version.cf_keypair_secret.value["secret_key"]
  }

  type = "Opaque"
}
