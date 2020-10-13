
# Create an NFS volume to store grafana configuration data
resource "aws_efs_file_system" "grafana_nfs" {
  creation_token = "${var.project}-${var.environment}-grafana-data"
  encrypted      = true

  lifecycle_policy {
    transition_to_ia = "AFTER_60_DAYS"
  }

  tags = {
    Name = "${var.project}-${var.environment}-prometheus-data"
  }
}

# Create a mount target in each AZ so that all worker nodes will have access
resource "aws_efs_mount_target" "grafana_az_mount" {
  for_each = data.aws_subnet_ids.private.ids

  file_system_id  = aws_efs_file_system.grafana_nfs.id
  subnet_id       = each.value
  security_groups = [data.aws_security_group.eks_workers.id]
}

# Add a k8s PersistentVolume to make use of the NFS volume
resource "kubernetes_persistent_volume" "grafana_nfs_pv" {
  metadata {
    name = "grafana-nfs-pv"
  }
  spec {
    capacity = {
      storage = "1Gi"
    }
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "gp2"
    persistent_volume_source {
      nfs {
        path   = "/"
        server = aws_efs_file_system.grafana_nfs.dns_name
      }
    }
  }
}

# Add a k8s PersistentVolumeClaim in the namespace for the grafana pod to use
resource "kubernetes_persistent_volume_claim" "grafana_nfs_pvc" {
  metadata {
    name      = "grafana-nfs-pvc"
    namespace = kubernetes_namespace.metrics.metadata[0].name
    labels = {
      app     = "grafana"
      release = "prometheus-operator"
    }
  }
  spec {
    access_modes = kubernetes_persistent_volume.grafana_nfs_pv.spec[0].access_modes
    resources {
      requests = {
        storage = kubernetes_persistent_volume.grafana_nfs_pv.spec[0].capacity.storage
      }
    }

    volume_name = kubernetes_persistent_volume.grafana_nfs_pv.metadata[0].name
  }
}
