# This Dockerfile is not directly used by the deployment. It is used when
# running tests over the project in GitLab CI. We need a Dockerfile in the root
# of the repo so that AutoDevOps will build an image we can test.
FROM registry.gitlab.developers.cam.ac.uk/uis/devops/infra/dockerimages/logan-terraform:1.3
ADD ./ ./
