---
title: Concepts and building blocks
sidebar_label: Concepts
sidebar_position: 1
---

## CI/CD Pipeline
We use Github actions to invoke the Cloudformation pipeline, it consists of 2 steps:
- `aws sam build`
- `aws sam deploy`
The `build` step compiles the container images, and the `deploy` step uses Cloudformation to get the resources to the desired state.

## Environment Configuration
Managed by `config.toml` in the backend repository.
This is the deploy step's configuration, determines where the artifacts are saved and allows configuration of parameters of each environment, such as image repositories and S3 to store build configurations.

## CloudFormation template
Managed by `tempalte.yaml` in the backend repository.
This is the configuration of your infrastructure and application setup, this configures how the Gateway, authenticator, application, logging and routes are setup.
