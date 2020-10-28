# Create/Update postgresql db user with kubernetes job
resource "random_string" "job_id" {
  length  = 8
  lower   = true
  upper   = false 
  special = false

  keepers = {
    password = var.db_app_password
  }
}

resource "kubernetes_namespace" "db_ops" {
  metadata {
    name = "db-ops"
  }
}

resource "kubernetes_secret" "db_create_users" {
  metadata {
    name      = "db-create-users"
    namespace = "db-ops"
  }

  data = {
    "create-user.sql" = <<-EOF
      DROP USER IF EXISTS ${var.db_app_user}
      CREATE USER ${var.db_app_user} with encrypted password "${var.db_app_password}";
      GRANT ALL PRIVILEGES on database ${var.db_name} to ${var.db_app_user};
EOF
    "RDS_MASTER_PASSWORD" = var.db_master_password
  }

  type = "Opaque"
}

resource "kubernetes_job" "db_create_users" {
  metadata {
    name      = "db-create-users-${random_string.job_id.result}"
    namespace = "db-ops"
  }

  spec {
    backoff_limit = 1

    template {
      metadata {}

      spec {
        volume {
          name = "db-create-users"

          secret {
            secret_name = "db-create-users"
          }
        }

        container {
          name    = "create-rds-user"
          image   = "commitdev/zero-k8s-utilities:0.0.3"
          command = ["sh"]
          args    = ["-c", "psql -U${var.db_master_user} -h database.${var.namespace} ${var.db_name} -a -f/db-ops/create-user.sql > /dev/null"]

          env {
            name  = "DB_ENDPOINT"
            value = "database.${var.namespace}"
          }

          env {
            name  = "DB_NAME"
            value = " ${var.db_name}"
          }

          env {
            name = "PGPASSWORD"

            value_from {
              secret_key_ref {
                name = "db-create-users"
                key  = "RDS_MASTER_PASSWORD"
              }
            }
          }

          volume_mount {
            name       = "db-create-users"
            mount_path = "/db-ops/create-user.sql"
            sub_path   = "create-user.sql"
          }
        }

        restart_policy = "Never"
      }
    }
  }
}

