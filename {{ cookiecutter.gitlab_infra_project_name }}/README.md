# {{ cookiecutter.product_name }}

This repository contains terraform configuration for {{ cookiecutter.product_name }}

The configuration assumes that the required *Product Scaffolding*
(product folder, meta and workspace projects, configuration bucket etc.)
has been deployed to Google Cloud by the Cloud Team.

## A tour of the deployment

A high-level tour of the deployment is as follows:

* A Cloud SQL instance and webapp database are configured in [sql.tf](sql.tf).
* A Cloud Run service for the webapp and its associated settings are configured
    in [webapp.tf](webapp.tf).
* GitLab CI variables and a service account for the CI job runner to use when
    **deploying** are configured in [ci_deploy.tf](ci_deploy.tf).
* GitLab CI variables and a service account for the CI job runner to use with
    **review apps** are configured in [ci_review.tf](ci_review.tf).

## Product configuration

The [locals.tf](./locals.tf) contains parameters required to configure the deployment.
Some of these values are pulled from the `config_v1.json` file which was created by the Cloud Team,
others need to be completed manually and are described below.

## Bootstrapping

Before this module can be deployed, there are some manual steps which must be performed.

### Initialise a workspace

> Before you can initialise a workspace the Cloud Team need to deploy the core infrastructure
> using the gcp-product-factory. If this has not been deployed for the specific workspace the
> following steps will not work.

> The following commands use the 
[logan](https://gitlab.developers.cam.ac.uk/uis/devops/tools/logan/) tool to aid consistent
terraform version usage.

> You will need to login to GCP before performing the following terraform 
commands. `gcloud auth application-default login` will log you into the GCP SDK,
making credentials available to terraform, as well as the gcloud cli.

Before you can create a specific workspace, you must initialise the terraform backend
in the default workspace:

> You'll need to add the --writable-workdir parameter on the very first run to
> allow terraform to create the .terraform.lock.hcl file.

```bash
logan --workspace=default --writable-workdir terraform init
```

Then create a new terraform workspace, for example "development":

> Terraform may complain about a read-only filesystem but the workspace will have been created.

```bash
logan --workspace=default terraform workspace new development
```

To initialise the created "development" workspace:

```bash
logan --workspace=development terraform init
```

Finally, run a full terraform apply.

```bash
logan --workspace=development terraform apply
```

### Extra secrets

A secret named "webapp-extra-secrets" should be created in the product-wide
**meta project** which contains per-workspace "extra" secrets. The contents 
of the secret should be a YAML dictionary keyed by workspace name containing 
extra secrets. The exact format is documented in 
[webapp_settings.tf](webapp_settings.tf).

YAML anchors can be used for secrets which are common to multiple workspaces:

```yaml
# Per-workspace extra secrets

.shared: &shared
  lookup:
    username: uis-something-something
    password: super-secret

production:
  <<: *shared

staging:
  <<: *shared

development:
  <<: *shared
```

The name of this "extra secret" should be added to the
`workspace_extra_secrets_secret_name` local in [locals.tf](locals.tf).

## Deploying via GitLab CI

This repository includes configuration for GitLab CI to allow automated
deployments to development, staging and production. When the terraform config is
applied appropriate credentials are added as CI variables.

To manually deploy a webapp to the "development" release:

1. Navigate to **CI/CD** > **Pipelines** in this project.
2. Click **Run pipeline**.
3. Set the CI variable `DEPLOY_ENABLED` to `development`.
4. Set the CI variable `WEBAPP_DOCKER_IMAGE` to the name of the webapp Docker
   image to deploy.
5. Click **Run pipeline**.

To deploy to staging or production, set `DEPLOY_ENABLED` to `staging`. Note that
deployments to production *must* go through staging first and will appear a
"manual" jobs in the pipeline.

The current "staging" release can be deployed to "production" via the
Environments page found at **Operations** > **Environments**. Click the "Play"
button next to the staging release and choose the deploy to production option
from the drop-down menu.

## Post deploy configuration

Some configuration needs to be applied manually after the first deployment to a new workspace.

{% if cookiecutter.database_type == "postgres" -%}
### Configuring Postgres users

By default, all Cloud SQL users are members of the `cloudsqlsuperuser` role. For
the webapp user, this is sub-optimal. The [db_roles.sql](db_roles.sql) file
contains configuration to drop the access levels for the webapp user.

If you haven't already, install the Google Cloud SQL proxy:

```bash
gcloud components install cloud_sql_proxy
```

Start the proxy and connect to the Cloud SQL instance:

```
cloud_sql_proxy -instances $(logan --nopull --quiet --notty terraform output sql_instance_connection_name)=tcp:5432
```

Retrieve the `admin` user's password and copy to the clipboard:

```bash
logan --nopull --quiet --notty terraform output sql_instance_password | xclip -i -sel clip
```

Apply the role configuration, pasting the admin user password when asked:

```bash
psql -h localhost -U admin -d webapp -1 -f db_roles.sql
```

{%- endif %}
## Updating Cloud Run services

By design, the Cloud Run service configured in this module is updated by GitLab
CI "out of band". This is usually fine except for when you want to change some
property of the service after a GitLab CI deployment. In this case you may find
that the terraform deployment does not succeed due to it trying to re-use an
existing revision name.  You can force terraform to re-generate the revision
name by removing the revision name resource from the state and re-applying:

```bash
logan terraform state rm module.webapp.random_id.webapp_revision_name
logan terraform apply
```

> **IMPORTANT:** Note that we use `terraform state rm` and not `terraform
> destroy -target`. If we were to use `destroy`, dependent resources would also
> be destroyed which includes the Cloud Run service itself.
