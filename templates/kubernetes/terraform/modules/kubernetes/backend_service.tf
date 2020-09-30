module "fileupload" {
  count = var.cf_signing_enabled ? 1 : 0
  source = "./fileupload"
}
