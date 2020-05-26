# Add the keys to AWS secrets manager
resource "aws_secretsmanager_secret" "secret" {
  name_prefix = var.name_prefix
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "string_secret" {
  count         = var.type == "string" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = var.value
}

resource "aws_secretsmanager_secret_version" "map_secret" {
  count         = var.type == "map" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = jsonencode(var.values)
}

resource "aws_secretsmanager_secret_version" "random_secret" {
  count         = var.type == "random" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = random_password.random[0].result
}

resource "random_password" "random" {
  # this allows terraform state to have an identifier for generated passwords
  keepers = {
    aws_secret = var.name_prefix
  }
  count             = var.type == "random" ? 1 : 0
  length            = var.random_length
  special           = true
  override_special  = "_-+."
  min_special       = 2
  min_numeric       = 2
  min_upper         = 2
}
