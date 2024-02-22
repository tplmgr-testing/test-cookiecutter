# webapp.tf describes resources for the deployment's default web application.
# More webapps can be supported in an individual project by copying this file
# and amending as necessary.

# Django secret key for the webapp.
resource "random_id" "webapp_secret_key" {
  byte_length = 64
}

# A Secret Manager secret which holds secret settings for the webapp.
module "webapp_secret_settings" {
  source  = "gitlab.developers.cam.ac.uk/uis/gcp-secret-manager/devops"
  version = "~> 4.0"

  project   = local.project
  region    = local.region
  secret_id = "webapp-secret-settings"

  # Settings for the web application which are secret. These are loaded into a
  # Secret Manager secret object and passed to the web application via a
  # sm://...  URL. This file can be no greater than 64KiB in size. It should be
  # a YAML-formatted file and the top-level keys are loaded as settings.
  secret_data = yamlencode(local.webapp_secret_settings)
}

# The web application's service account needs to be able to read the settings
# secret.
resource "google_secret_manager_secret_iam_member" "webapp_secret_settings" {
  project   = module.webapp_secret_settings.project
  secret_id = module.webapp_secret_settings.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.webapp.service_account.email}"
}

# Non-secret configuration for the webapp.
resource "google_storage_bucket_object" "webapp_settings" {
  name    = "webapp-settings"
  bucket  = local.workspace_config.config_bucket
  content = yamlencode(local.webapp_settings)
}


# A database user for the web-application.
resource "random_password" "webapp_sql_user_password" {
  length  = 16
  special = false
}

resource "google_sql_user" "webapp_sql_user" {
  name     = local.webapp_sql_user
  instance = module.sql_instance.instance_name
  password = random_password.webapp_sql_user_password.result
}

locals {
  extra_settings_urls = join(",", [
    module.webapp_secret_settings.url,
  ])
}

# Default web-application.
module "webapp" {
  source = "git::https://gitlab.developers.cam.ac.uk/uis/devops/infra/terraform/gcp-cloud-run-app.git?ref=v8"

  project                            = local.project
  cloud_run_region                   = local.region
  image_name                         = "${local.container_images.webapp_base}:${local.container_images.webapp_tag}"
  grant_sql_client_role_to_webapp_sa = true

  # max_scale * parallelism of container (==4) should not exceed maximum
  # connection count of database.
  max_scale = 10

  # Only attempt to configure a DNS name if the domain is verified. Otherwise
  # the domain mapping cannot be created.
  dns_name = (
    (!local.webapp_use_cloud_load_balancer && local.domain_verification.verified)
    ? coalesce(local.webapp_custom_dns_name, trimsuffix(local.webapp_dns_name, "."))
    : ""
  )

  sql_instance_connection_name = module.sql_instance.instance_connection_name

  environment_variables = {
    EXTRA_SETTINGS_URLS = local.extra_settings_urls
  }

  allowed_ingress = local.webapp_use_cloud_load_balancer ? "internal-and-cloud-load-balancing" : "all"
  {%- if cookiecutter.notification_channel != "" %}

  alert_notification_channels = local.notification_channels
  {%- endif %}

  providers = {
    google.stackdriver = google.monitoring
  }
}

locals {
  # Constructed DNS name for webapp. Based on service name and project DNS zone.
  webapp_dns_name = join(".", [
    module.webapp.service.name,
    local.workspace_config.dns_managed_zone.dns_name,
  ])
}

# DNS records for webapp. These are created irrespective of the any custom DNS
# name. For custom DNS name-hosted webapps, you will probably need a further
# CNAME record pointing to this record.
resource "google_dns_record_set" "webapp" {
  count = module.webapp.domain_mapping_present ? 1 : 0

  managed_zone = local.workspace_config.dns_managed_zone.name

  ttl  = 300
  name = local.webapp_dns_name
  type = module.webapp.domain_mapping_resource_record.type
  rrdatas = [
    module.webapp.domain_mapping_resource_record.rrdata,
  ]
}
