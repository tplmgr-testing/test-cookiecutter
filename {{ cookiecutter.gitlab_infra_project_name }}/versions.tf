# versions.tf specifies minimum versions for providers and terraform.

terraform {
  required_version = "~> 1.1"

  # Specify the required providers, their version restrictions and where to get them.
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 3.14"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.20"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.20"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
