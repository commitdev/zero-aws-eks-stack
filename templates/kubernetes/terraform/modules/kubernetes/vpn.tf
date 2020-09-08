# Create VPN

# generate VPN configuration
locals {
  namespace  = "vpn"

  db_identifier          = "${var.project}-${var.environment}"
  destination_subnets    = join(",", [for s in data.aws_subnet.my_db_subnet : s.cidr_block])
  server_address	 = var.vpn_server_address
  server_privatekey_name = "${var.project}-${var.environment}-vpn-wg-privatekey-${var.random_seed}"
  client_peers           = join("\n", data.template_file.vpn_client_data_json.*.rendered)
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

## get client public keys
data "template_file" "vpn_client_data_json" {
  template = file("${path.module}/files/wireguard-peer.tpl")
  count    = length(var.vpn_client_publickeys)

  vars = {
    client_pub_key       = element(values(var.vpn_client_publickeys[count.index]), 0)
    client_ip            = element(keys(var.vpn_client_publickeys[count.index]), 0)
    persistent_keepalive = 25
  }
}

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
    name = "wg-secret"
    namespace = local.namespace
  }

  data = {
    privatekey = jsondecode(data.aws_secretsmanager_secret_version.vpn_private_key.secret_string)["key"]
  }

  type = "Opaque"
}

resource "kubernetes_config_map" "vpn_configmap" {
  metadata {
    name = "wg-configmap"
    namespace = local.namespace
  }

  data = {
    "wg0.conf" = "[Interface]\nAddress = ${local.server_address}\nListenPort = 51820\nPostUp = wg set wg0 private-key /etc/wireguard/privatekey && iptables -A FORWARD -s ${local.server_address} -d ${local.destination_subnets} -j ACCEPT && iptables -A FORWARD -s ${local.server_address} -j DROP && iptables -t nat -A POSTROUTING -s ${local.server_address} -o eth0 -j MASQUERADE\nPostDown = iptables -D FORWARD -s ${local.server_address} -d ${local.destination_subnets} -j ACCEPT && iptables -D FORWARD -s ${local.server_address} -j DROP && iptables -t nat -D POSTROUTING -s ${local.destination_subnets} -o eth0 -j MASQUERADE\n\n${local.client_peers}\n"
  }
}

resource "kubernetes_service" "wireguard" {
  metadata {
    name = "wireguard"
    namespace = local.namespace

    labels = {
      app = "wireguard"
    }

    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
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

    type = "LoadBalancer"
    external_traffic_policy = "Local"
  }
}

resource "kubernetes_deployment" "wireguard" {
  metadata {
    name = "wireguard"
    namespace = local.namespace
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
          image   = "masipcat/wireguard-go:latest"
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

