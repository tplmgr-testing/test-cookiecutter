# locals.tf contain definitions for local variables which are of general utility
# within the configuration.

# These locals are provided by the DevOps Cloud Team.
locals {
  # Bucket and path for GCP-admin provided configuration.
  config_bucket = "{{ cookiecutter.product_configuration_bucket }}"
  config_path   = "{{ cookiecutter.product_configuration_path }}"
}

# These locals come from the manual bootstrapping steps.
locals {
  # Base URLs of GitLab instance holding deployment and webapp projects.
  gitlab_base_url = "https://gitlab.developers.cam.ac.uk/"

  # Name of Secret Manager secret which contains the GitLab access token for
  # this deployment.
  gitlab_access_token_secret_name = "gitlab-access-token"

  # Project which contains the GitLab access token secret.
  gitlab_access_token_secret_project = local.product_meta_project

  # If non-empty for a particular workspace, this is a custom DNS name for the
  # webapp. It should be the FQDN of the webapp *without trailing dot*.
  #
  # Domain mappings for these custom DNS domains will only be created if the
  # verification flag in workspace_domain_verification is "true" for the given
  # workspace.
  workspace_webapp_custom_dns_name = {
    # These should be of the form:
    #
    #   <workspace name> = "<custom DNS>"
  }

  # Name of secret in meta project containing workspace-specific secrets. See
  # the README for the format of this secret. If blank, no workspace-specific
  # secrets are used.
  workspace_extra_secrets_secret_name = ""
}

# This data source retrieves the webapp project from GitLab based on the project id
# specified when running cookiecutter. This is used in the following locals section.
data "gitlab_project" "webapp" {
  id = "{{ cookiecutter.gitlab_webapp_project_id }}"
}

# These locals define common configuration parameters for the deployment.
locals {
  # Default region for resources.
  region = "europe-west2"

  # SQL instance configuration
  sql_instance = {
    # Initial database in SQL instance.
    db_name = "webapp"

    # Initial user for SQL instance. The user is an "admin" user
    # with CREATE ROLE and CREATE DATABASE privileges.
    #
    # See: https://cloud.google.com/sql/docs/postgres/create-manage-users
    user_name = "admin"

    # Tier for production database. Other workspaces use "db-f1-micro".
    production_tier = "db-f1-micro"
  }

  # Webapp SQL user
  webapp_sql_user = "webapp"

  # Whether to configure a Cloud Load Balancer for the "webapp" application as
  # opposed to using Cloud Run's default custom domain mapping behaviour.
  webapp_use_cloud_load_balancer = "{{ cookiecutter.use_cloud_load_balancer }}"

  # Container images used in this deployment. Generally these
  # should be tagged explicitly with the Git commit SHA for the exact version to
  # deploy. They are specified per-workspace with generic "latest from master"
  # fallbacks if not otherwise specified.
  #
  # The full image name is formed by concatenating "..._base" and "..._tag"
  # locals which makes it convenient to specify only branches and/or commit
  # SHAs.
  container_images = merge(
    local.default_container_images,
    lookup({
      # Empty until we know the exact image SHA to deploy.
      production = {}
      staging    = {}
    }, terraform.workspace, {})
  )
  {% if cookiecutter.notification_channel != "" -%}
  notification_channels = [local.gcp_config.notification_channels.email.{{ cookiecutter.notification_channel }}]
  {%- endif %}
  # Default base URLs and images for container_images if none are specified
  # for the workspace.
  default_container_images = {
    webapp_base = join("/", [
      local.gcp_config.artifact_registry_docker_repository,
      data.gitlab_project.webapp.path,
      data.gitlab_project.webapp.default_branch
    ])
    webapp_tag = "latest"
  }
}

# These locals are derived from resources, data sources or other locals.
locals {
  domain_verification = local.workspace_config.domain_verification

  # True if this is a "production-like" workspace.
  is_production = terraform.workspace == "production"

  # Project id of product-specific meta project.
  product_meta_project = local.gcp_config.product_meta_project

  # Project id for workspace-specific project.
  project = local.workspace_config.project_id

  # Lookup per-workspace custom webapp domain.
  webapp_custom_dns_name = lookup(
    local.workspace_webapp_custom_dns_name, terraform.workspace, ""
  )
}
