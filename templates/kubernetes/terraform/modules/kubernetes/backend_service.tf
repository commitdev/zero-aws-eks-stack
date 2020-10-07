module "fileupload" {
  source = "./fileupload"

  count = var.cf_signing_enabled ? 1 : 0

  project = var.project
  namespace = kubernetes_namespace.app_namespace.metadata[0].name
}
