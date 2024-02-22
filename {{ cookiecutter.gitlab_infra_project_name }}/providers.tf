# This provider runs in the context of the person invoking Terraform (i.e. your personal @cam.ac.uk account).
# This is simply used to create tokens to impersonate other, more powerful, service accounts.
provider "google" {
  alias = "impersonation"
}

# Generate a token for the terraform-deploy service account for the current workspace.
data "google_service_account_access_token" "terraform_deploy" {
  target_service_account = local.workspace_config.terraform_sa_email
  scopes                 = ["cloud-platform"]

  provider = google.impersonation
}

provider "google" {
  access_token = data.google_service_account_access_token.terraform_deploy.access_token
  project      = local.project
  region       = local.region
}

provider "google-beta" {
  access_token = data.google_service_account_access_token.terraform_deploy.access_token
  project      = local.project
  region       = local.region
}

# This monitoring provider is used to create monitoring resources in the product meta project. The workspace
# terraform-deploy service account is granted a minimum set of permissions on the meta project to enable this to work
# without needing an additional service account.
provider "google" {
  alias        = "monitoring"
  access_token = data.google_service_account_access_token.terraform_deploy.access_token
  project      = local.product_meta_project
  region       = local.region
}

# A GitLab bot user access token is available in a secret manager secret.
data "google_secret_manager_secret_version" "gitlab_access_token" {
  secret  = local.gitlab_access_token_secret_name
  project = local.gitlab_access_token_secret_project
}

# A GitLab provider is used to interact with projects on the Developer Hub.
provider "gitlab" {
  token    = data.google_secret_manager_secret_version.gitlab_access_token.secret_data
  base_url = local.gitlab_base_url
}
