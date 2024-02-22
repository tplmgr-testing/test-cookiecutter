# webapp_settings.tf defines secret and non-secret settings for the webapp which
# is used by webapp.tf.

# TODO: Document the expected form of the extra settings secret here. For
# example:
#
# The extra settings secret should have the following form:
#
#   <workspace name>:
#     # Optional lookup credentials
#     lookup:
#       username: "some-lookup-group"
#       password: "P455w0rd!"
#
#     # OAuth2 client credentials
#     oauth2:
#       key: "some-oauth2-client-id"
#       secret: "some-oauth2-secret"

locals {
  # TODO: Extract any extra secrets. For example:
  #
  # # Credentials for lookup are stored in a "lookup" dict in the extra secrets.
  # lookup_secrets = lookup(local.extra_secrets, "lookup", {})

  # Credentials for oauth2 are stored in a "oauth2" dict in the extra secrets.
  oauth2_secrets = lookup(local.extra_secrets, "oauth2", {})

  # Secret settings for the webapp. Stored in a Google Secret Manager secret.
  # The YAML encoding cannot be larger than 64KiB.
  webapp_secret_settings = {
    SECRET_KEY = random_id.webapp_secret_key.b64_url

    DATABASES = {
      default = {
        ENGINE       = "django.db.backends.postgresql"
        CONN_MAX_AGE = 60 # seconds
        HOST         = "/cloudsql/${module.sql_instance.instance_connection_name}"
        NAME         = local.sql_instance.db_name
        USER         = local.webapp_sql_user
        PASSWORD     = google_sql_user.webapp_sql_user.password
      }
    }

    # An example of using extra secrets:
    #
    # # If no lookup secrets are defined, use "None" as values for these settings.
    # UCAMLOOKUP_USERNAME = lookup(local.lookup_secrets, "username", null)
    # UCAMLOOKUP_PASSWORD = lookup(local.lookup_secrets, "password", null)

    # If no oauth2 secrets are defined, use "None" as values for these settings otherwise the
    # Django container will crash as it expects these environment vars to be defined.
    SOCIAL_AUTH_GOOGLE_OAUTH2_KEY    = lookup(local.oauth2_secrets, "key", null)
    SOCIAL_AUTH_GOOGLE_OAUTH2_SECRET = lookup(local.oauth2_secrets, "secret", null)
  }

  # Non-secret settings. This map is YAML encoded and stored in a Google Cloud Storage
  # object (see google_storage_bucket_object.webapp_settings in webapp.tf).
  webapp_settings = {}
}

locals {
  # This is some deep terraform magic to conditionally read and parse the extra
  # secrets secret but only if local.workspace_extra_secrets_secret_name is
  # non-empty. If local.workspace_extra_secrets_secret_name is empty then
  # all_workspace_extra_secrets will just be an empty map.
  all_workspace_extra_secrets = coalescelist(
    [
      for idx in range(local.workspace_extra_secrets_secret_name == "" ? 0 : 1) :
      yamldecode(data.google_secret_manager_secret_version.extra_secrets[idx].secret_data)
    ], [{}]
  )[0]

  # Extract the *per-workspace* extra secrets if present. Otherwise, this is an
  # empty map.
  extra_secrets = lookup(local.all_workspace_extra_secrets, terraform.workspace, {})
}

# Read the contents of the extra settings secret. Note that this will only
# actually be read if local.workspace_extra_secrets_secret_name is non-empty
# due to the count parameter.
data "google_secret_manager_secret_version" "extra_secrets" {
  count = local.workspace_extra_secrets_secret_name == "" ? 0 : 1

  project = local.product_meta_project
  secret  = local.workspace_extra_secrets_secret_name
}
