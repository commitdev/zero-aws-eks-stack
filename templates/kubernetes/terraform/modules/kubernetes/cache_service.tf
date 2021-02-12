data "aws_elasticache_replication_group" "redis" {
  count = var.cache_store == "redis" ? 1 : 0

  replication_group_id = "${var.project}-${var.environment}-redis"
}

data "aws_elasticache_cluster" "memcached" {
  count = var.cache_store == "memcached" ? 1 : 0

  cluster_id = "${var.project}-${var.environment}-memcached"
}

locals {
  endpoint_address = var.cache_store == "redis" ? data.aws_elasticache_replication_group.redis[0].primary_endpoint_address : var.cache_store == "memcached" ? data.aws_elasticache_cluster.memcached[0].cluster_address : ""
}

resource "kubernetes_service" "app_cache" {
  count = local.endpoint_address == "" ? 0 : 1

  ## this should match the deployable backend's name/namespace
  metadata {
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    name      = "cache-${var.cache_store}"
  }
  spec {
    type          = "ExternalName"
    external_name = local.endpoint_address
  }
}
