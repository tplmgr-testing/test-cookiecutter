{% if cookiecutter.database_type == "postgres" -%}
-- Ensure that the webapp user doesn't have create role or database rights.
ALTER ROLE webapp WITH NOCREATEDB NOCREATEROLE LOGIN;

-- Ensure that the webapp user isn't a member of the `cloudsqlsuperuser` role.
REVOKE cloudsqlsuperuser FROM webapp;

-- Allow the webapp user to connect to the webapp database and create temporary
-- tables.
GRANT ALL PRIVILEGES ON DATABASE webapp TO webapp;
{% elif cookiecutter.database_type == "mysql" -%}
-- For MySQL, no database schema changes are required.
{%- endif %}
