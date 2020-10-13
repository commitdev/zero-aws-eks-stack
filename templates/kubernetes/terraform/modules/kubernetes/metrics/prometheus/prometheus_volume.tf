
# Create an NFS volume to store prometheus metrics data
resource "aws_efs_file_system" "prometheus_nfs" {
  creation_token = "${var.project}-${var.environment}-prometheus-data"
  encrypted      = true

  lifecycle_policy {
    transition_to_ia = "AFTER_60_DAYS"
  }

  tags = {
    Name = "${var.project}-${var.environment}-prometheus-data"
  }
}

# Create a mount target in each AZ so that all worker nodes will have access
resource "aws_efs_mount_target" "prometheus_az_mount" {
  for_each = data.aws_subnet_ids.private.ids

  file_system_id  = aws_efs_file_system.prometheus_nfs.id
  subnet_id       = each.value
  security_groups = [data.aws_security_group.eks_workers.id]
}


# Add a k8s PersistentVolume to make use of the NFS volume
resource "kubernetes_persistent_volume" "prometheus_nfs_pv" {
  metadata {
    name = "prometheus-nfs-pv"
  }
  spec {
    capacity = {
      storage = "${var.prometheus_storage_capacity}Gi"
    }
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "gp2"
    persistent_volume_source {
      nfs {
        path   = "/"
        server = aws_efs_file_system.prometheus_nfs.dns_name
      }
    }
  }
}
