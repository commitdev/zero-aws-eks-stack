# Create VPN

# generate VPN configuration
locals {
  namespace = "vpn"

  db_identifier          = "${var.project}-${var.environment}"
  destination_subnets    = join(",", [for s in data.aws_subnet.my_db_subnet : s.cidr_block])
  server_address         = var.vpn_server_address
  server_privatekey_name = "${var.project}-${var.environment}-vpn-wg-privatekey-${var.random_seed}"
  client_publickeys      = var.vpn_client_publickeys
  client_endpoint_dns	 = "vpn.${var.external_dns_zone}"
}

## get destination database subnets
data "aws_db_instance" "my_db" {
  db_instance_identifier = local.db_identifier
}
data "aws_db_subnet_group" "my_db_subnetgroup" {
  name = data.aws_db_instance.my_db.db_subnet_group
}
data "aws_subnet" "my_db_subnet" {
  for_each = data.aws_db_subnet_group.my_db_subnetgroup.subnet_ids
  id       = each.value
}

## TBD: get other destination subnets

## get server config
data "template_file" "vpn_server_conf" {
  template = file("${path.module}/files/wireguard-wg0-conf.tpl")

  vars = {
    tpl_server_address      = local.server_address
    tpl_destination_subnets = local.destination_subnets
    tpl_client_peers        = join("\n", data.template_file.vpn_client_peers_section.*.rendered)
  }
}

data "template_file" "vpn_client_peers_section" {
  template = file("${path.module}/files/wireguard-peer.tpl")
  count    = length(local.client_publickeys)

  vars = {
    tpl_client_name    = local.client_publickeys[count.index][0]
    tpl_client_ip      = local.client_publickeys[count.index][1]
    tpl_client_pub_key = local.client_publickeys[count.index][2]
  }
}

## get server private key
data "aws_secretsmanager_secret" "vpn_private_key" {
  name = local.server_privatekey_name
}
data "aws_secretsmanager_secret_version" "vpn_private_key" {
  secret_id = data.aws_secretsmanager_secret.vpn_private_key.id
}

resource "kubernetes_namespace" "vpn_namespace" {
  metadata {
    name = local.namespace
  }
}

resource "kubernetes_secret" "vpn_private_key" {
  metadata {
    name      = "wg-secret"
    namespace = kubernetes_namespace.vpn_namespace.metadata[0].name
  }

  data = {
    privatekey = data.aws_secretsmanager_secret_version.vpn_private_key.secret_string
  }

  type = "Opaque"
}

resource "kubernetes_config_map" "vpn_configmap" {
  metadata {
    name      = "wg-configmap"
    namespace = kubernetes_namespace.vpn_namespace.metadata[0].name
  }

  data = {
    "wg0.conf"      = data.template_file.vpn_server_conf.rendered
  }
}

resource "kubernetes_service" "wireguard" {
  metadata {
    name      = "wireguard"
    namespace = kubernetes_namespace.vpn_namespace.metadata[0].name

    labels = {
      app = "wireguard"
    }

    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
      "external-dns.alpha.kubernetes.io/hostname" = local.client_endpoint_dns
    }
  }

  spec {
    port {
      name        = "wg"
      protocol    = "UDP"
      port        = 51820
      target_port = "51820"
    }

    selector = {
      app = "wireguard"
    }

    type                    = "LoadBalancer"
    external_traffic_policy = "Local"
  }
}

resource "kubernetes_deployment" "wireguard" {
  metadata {
    name      = "wireguard"
    namespace = kubernetes_namespace.vpn_namespace.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "wireguard"
      }
    }

    template {
      metadata {
        labels = {
          app = "wireguard"
          # this hash is to update the deployment whenever configmap is updated with new users
          configmap_version = sha1(data.template_file.vpn_server_conf.rendered)
        }
      }

      spec {
        volume {
          name = "cfgmap"

          config_map {
            name = "wg-configmap"
          }
        }

        volume {
          name = "secret"

          secret {
            secret_name = "wg-secret"
          }
        }

        init_container {
          name    = "sysctls"
          image   = "busybox"
          command = ["sh", "-c", "sysctl -w net.ipv4.ip_forward=1 && sysctl -w net.ipv4.conf.all.forwarding=1"]

          security_context {
            capabilities {
              add = ["NET_ADMIN"]
            }

            privileged = true
          }
        }

        container {
          name    = "wireguard"
          image   = "commitdev/wireguard-go:0.0.1"
          command = ["sh", "-c", "echo \"Public key '$(wg pubkey < /etc/wireguard/privatekey)'\" && /entrypoint.sh"]

          port {
            name           = "wireguard"
            container_port = 51820
            protocol       = "UDP"
          }

          env {
            name  = "LOG_LEVEL"
            value = "info"
          }

          resources {
            limits {
              memory = "256Mi"
            }

            requests {
              cpu    = "100m"
              memory = "64Mi"
            }
          }

          volume_mount {
            name       = "cfgmap"
            mount_path = "/etc/wireguard/wg0.conf"
            sub_path   = "wg0.conf"
          }

          volume_mount {
            name       = "secret"
            mount_path = "/etc/wireguard/privatekey"
            sub_path   = "privatekey"
          }

          security_context {
            capabilities {
              add = ["NET_ADMIN"]
            }

            privileged = true
          }
        }
      }
    }
  }
}

# Create Kubernetes role and binding to use arbitrary group 'vpn-users'. This group has been added by administor and mapped to user roles(developer & operator).
resource "kubernetes_role" "wireguard" {
  metadata {
    name      = "wireguard"
    namespace = kubernetes_namespace.vpn_namespace.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/exec"]
    verbs      = ["exec", "list", "create"]
  }
}

resource "kubernetes_role_binding" "wireguard" {
  metadata {
    name      = "wireguard"
    namespace = kubernetes_namespace.vpn_namespace.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "wireguard"
  }
  subject {
    kind      = "Group"
    name      = "vpn-users"
    api_group = "rbac.authorization.k8s.io"
  }
}
