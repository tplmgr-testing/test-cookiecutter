# sql.tf defines resources for the Cloud SQL instance and database.

# A random name for the instance.
resource "random_id" "sql_instance_name" {
  byte_length = 4
  prefix      = "sql-"
}

# We make use of the opinionated Cloud SQL module provided by Google at
# https://registry.terraform.io/modules/GoogleCloudPlatform/sql-db/.
#
# The double-"/" is required. No, I don't know why.
module "sql_instance" {
  {% if cookiecutter.database_type == "postgres" -%}
  source           = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version          = "~> 12.0"
  database_version = "POSTGRES_14"
  {%- elif cookiecutter.database_type == "mysql" -%}
  source           = "GoogleCloudPlatform/sql-db/google//modules/mysql"
  version          = "~> 12.0"
  database_version = "MYSQL_8_0"
  {%- endif %}

  name = random_id.sql_instance_name.hex

  project_id        = local.project
  region            = local.region
  zone              = "${local.region}-b" # Can be any of a, b or c. Take your pick!
  availability_type = local.is_production ? "REGIONAL" : "ZONAL"

  # Some parameters depend on whether this is a production workspace.
  tier = local.is_production ? local.sql_instance.production_tier : "db-f1-micro"

  # Default database and user.
  db_name   = local.sql_instance.db_name
  user_name = local.sql_instance.user_name

  # Make automated backups each day at 1AM.
  backup_configuration = {
    enabled    = true
    start_time = "01:00"

    {% if cookiecutter.database_type == "postgres" -%}
    # Ignored for Postgres instances but the module requires that this is set to
    # some value.
    binary_log_enabled = false
    {%- elif cookiecutter.database_type == "mysql" -%}
    binary_log_enabled = true
    {%- endif %}

    # Store backups in our preferred region.
    location = local.region

    point_in_time_recovery_enabled = false # default
    retained_backups               = null  # default
    retention_unit                 = null  # default
    transaction_log_retention_days = null  # default
  }

  # Configure the maintenance window explicitly.
  maintenance_window_day  = 7 # Sunday
  maintenance_window_hour = 2 # 2AM

  # Increased creation timeout (default: 10m).
  create_timeout = "20m"

  # Configure deletion protection explicitly.
  deletion_protection = true
}
