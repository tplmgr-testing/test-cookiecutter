# webapp_load_balancer.tf configures Cloud Load Balancer resources for the
# "webapp" application. Note that the load balancer must be enabled in locals.tf
# for resources in this file to be created.
#
# If use of the load balancer is enabled, webapp.tf will set the
# `allowed_ingress` attribute on the corresponding Cloud Run service so that it
# cannot be reached from the public Internet except by way of the load balancer.

# A network endpoint group for the "webapp" application.
resource "google_compute_region_network_endpoint_group" "webapp" {
  count = local.webapp_use_cloud_load_balancer ? 1 : 0

  name                  = "webapp"
  network_endpoint_type = "SERVERLESS"
  region                = local.region
  cloud_run {
    service = module.webapp.service.name
  }

  provider = google-beta
}

# A load balancer for the "webapp" application. This is just a set of sane
# defaults. See the full documentation at [1] for customisation.
#
# [1] https://registry.terraform.io/modules/GoogleCloudPlatform/lb-http/google/latest/submodules/serverless_negs
module "webapp_http_load_balancer" {
  count = local.webapp_use_cloud_load_balancer ? 1 : 0

  # The double slash is important(!)
  source  = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version = "~> 6.0"

  project = local.project
  name    = "webapp"

  ssl            = true
  https_redirect = true

  # Issue certificates for the "internal" DNS name and, optionally, for the
  # custom DNS name. In order for Google to issue certificates the domain must
  # be verified. This does not apply if we bring our own certificates and in
  # that case one can remove the check on local.domain_verification.verified.
  managed_ssl_certificate_domains = concat(
    [trimsuffix(local.webapp_dns_name, ".")],
    (local.domain_verification.verified && local.webapp_custom_dns_name != "") ? [local.webapp_custom_dns_name] : []
  )

  backends = {
    default = {
      description             = null
      enable_cdn              = false
      custom_request_headers  = null
      custom_response_headers = null
      security_policy         = null

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      groups = [
        {
          group = google_compute_region_network_endpoint_group.webapp[0].id
        }
      ]

      # Currently Cloud IAP is not supported for Cloud Run endpoints. We still
      # need to specify that we don't want to use it though :).
      iap_config = {
        enable               = false
        oauth2_client_id     = null
        oauth2_client_secret = null
      }
    }
  }
}

# DNS records for webapp. For load-balanced applications, these are created
# irrespective of the any custom DNS name. For custom DNS name-hosted webapps,
# you will probably need a further CNAME record pointing to this record.
resource "google_dns_record_set" "load_balancer_webapp" {
  count = local.webapp_use_cloud_load_balancer ? 1 : 0

  managed_zone = local.workspace_config.dns_managed_zone.name

  ttl  = 300
  name = local.webapp_dns_name
  type = "A"
  rrdatas = [
    module.webapp_http_load_balancer[0].external_ip
  ]
}
