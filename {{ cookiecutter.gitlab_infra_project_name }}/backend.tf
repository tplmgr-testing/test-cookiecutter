# backend.tf configures the teraform remote state backend.

terraform {
  backend "gcs" {
    # This bucket has been created by the Powers That Be for our use.
    bucket = "{{ cookiecutter.product_configuration_bucket }}"
    prefix = "terraform/{{ cookiecutter.product_slug }}"

    # Product-wide terraform-state service account. This value must hard-coded.
    impersonate_service_account = "{{ cookiecutter.terraform_state_sa_email }}"
  }
}
