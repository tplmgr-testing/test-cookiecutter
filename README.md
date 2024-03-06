# Boilerplate Google Cloud Deployment

This repository contains the [cookiecutter](https://github.com/cookiecutter/cookiecutter)
configuration which can be used to create a new Google Cloud Deployment for a web application based
on our [web application boilerplate](https://gitlab.developers.cam.ac.uk/uis/devops/webapp-boilerplate).

## Prerequisites

This boilerplate is designed to deploy one of the UIS DevOps team's [standard
products](https://guidebook.devops.uis.cam.ac.uk/en/latest/notes/gcp-deployments/).
As such, some initial [Cloud
Platform](https://guidebook.devops.uis.cam.ac.uk/en/latest/reference/cloud-platform/)
tasks must have been completed before this template will work.

These tasks are usually performed by a member of the DevOps Cloud Team who can
be reached via the [Cloud Team MS Teams
channel](https://teams.microsoft.com/l/channel/19%3afd77aa792d2243d4ae3818ee4b17d55e%40thread.tacv2/Cloud%2520Team?groupId=8b9ab893-3917-42bb-ba20-6cbd4bd2d304&tenantId=49a50445-bdfa-4b79-ade3-547b4f3986e9).

- A "product" must have been deployed via the
  [gcp-product-factory](https://gitlab.developers.cam.ac.uk/uis/devops/infra/gcp-product-factory)
  repository.
- A GKE-hosted GitLab runner must have been deployed via the
  [gitlab-runner-infrastructure](https://gitlab.developers.cam.ac.uk/uis/devops/devhub/gitlab-runner-infrastructure)
  repository.

## Usage

1. Install cookiecutter and run it against this repo.

    ```bash
    pip install --user cookiecutter
    cookiecutter https://gitlab.developers.cam.ac.uk/uis/devops/gcp-deploy-boilerplate.git
    ```

    > If you've not already authenticated against gitlab, you'll be prompted for
    > a username/password. You'll need to supply your username and a [personal
    > access
    > token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html)).

2. Cookiecutter will ask you for a number of input values. The first values can
    be retrieved from the `configuration_v1` file in the `meta` projects
    `*-config-*` bucket.

    - **product_name**: The product display name
    - **product_slug**: The product slug
    - **product_configuration_bucket**: A Google Cloud Storage bucket containing
      this product's configuration files.
    - **product_configuration_path**: The path within the
        "product_configuration_bucket" of a JSON-formatted configuration for
        this product
    - **use_existing_notification_channel**: Boolean variable. if 'true', the `alert_notification_channels`
        option will be added to the `webapp` module.
    - **existing_notification_channel**: Name of the key in JSON-formatted configuration for
        this product, that contains information about notification channel for alerts. Defined
        in the `gcp-product-factory`. If **use_existing_notification_channel** is 'false' this variable
        can be ignored. Simply press enter to continue. If **use_existing_notification_channel** is set to 'true',
        the valid notification channel key must be provided.
    - **terraform_state_sa_email**: The email address of the product-specific
        service account used to access this product's terraform state files

    The remaining values can be retrieved from Gitlab or are based on the
    project.

    - **gitlab_infra_project_name**: The (lowercase) name of the GitLab project
        git repo for the product deployment code (usually 'infrastructure').
    - **gitlab_infra_project_id**: Numeric id of the GitLab repository for the
      product deployment code<sup>1</sup>.
    - **gitlab_webapp_project_id**: Numeric id of the GitLab repository for the
      product web application code<sup>1</sup>.
    - **database_type**: Type of database,  MySQL or Postgres.
    - **use_cloud_load_balancer**: If "true", use a Cloud Load Balancer in place
        of the default Cloud Run one. Note that this does *not* currently
        disable the default Cloud Run endpoint. Currently only `true` is
        suitable answer.

    <sup>1</sup> You can also use paths to the project here but numeric ids are
    stable across renames of the project.

3. Once your project is generated visit its `/README.md` for the next steps.  

## Developing this boilerplate

Often when developing changes to this boilerplate you'll want to test a specific branch of this code.
You can do that with the following command.

```bash
cookiecutter https://gitlab.developers.cam.ac.uk/uis/devops/gcp-deploy-boilerplate.git --checkout <branch>
```

testid