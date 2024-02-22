# config.tf provides access to the configuration for the product provided by DevOps Cloud Team.

# Machine-readable configuration is provided to us as a storage object.
data "google_storage_bucket_object_content" "configuration_json" {
  bucket = local.config_bucket
  name   = local.config_path

  # The config json file is read by your personal user account. Speak to the DevOps Cloud Team if you require access.
  provider = google.impersonation
}

locals {
  gcp_config       = jsondecode(data.google_storage_bucket_object_content.configuration_json.content)
  workspace_config = local.gcp_config.workspaces[terraform.workspace]
}
