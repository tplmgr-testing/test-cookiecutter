# outputs.tf defines output values from the configuration which are useful to other users.

output "sql_instance_connection_name" {
  description = "Connection string for Cloud SQL instance."
  value       = module.sql_instance.instance_connection_name
}

output "sql_instance_user" {
  description = "SQL admin username."
  value       = local.sql_instance.user_name
}

output "sql_instance_password" {
  description = "SQL admin password. Use terraform's -json switch to view this value."
  value       = module.sql_instance.generated_user_password
  sensitive   = true
}

output "webapp_dns_name" {
  description = <<EOI
DNS domain name of created webapp address. This will always be somewhere in the
project DNS zone irrespective of whether a custom DNS domain has been set.
EOI
  value       = local.webapp_dns_name
}
