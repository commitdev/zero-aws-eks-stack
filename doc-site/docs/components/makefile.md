---
title: Explaining the Makefile in your repository
sidebar_label: Makefile Lifecycle
sidebar_position: 2
---

## Overview
The [Makefile] shipped with your repository drives the creation of your infrastructure, it defines the order of execution in its `apply` make target.

The [Makefile] is idempotent by design, meaning when `zero apply` runs it will attempt to reach the same final state every time. Therefore if the script determines a resource has previously been created it will skip the creation when run again, meaning `zero apply` can be re-run after initial setup.

## Targets Explained
Some of the steps are used for initializing the infrastructure, and some steps can also be used for updating and maintaining the infrastructure.

All the targets can be run with the environment variable `ENVIRONMENT=<prod|stage>` to target the corresponding environment, which defaults to `stage`

## Helpful targets for day-to-day use

### `apply-shared-env`
Runs `terraform apply` in your `terraform/environments/shared` directory. This terraform is responsible for resources shared between both staging/production. For example, IAM users and groups.
### `apply-env`
Runs `terraform apply` in your `terraform/environments/<env>` directory. This terraform represents the infrastructure resources in your AWS account: VPC, S3 buckets, EKS cluster, RDS database, etc.
### `apply-k8s-utils`
Runs `terraform apply` in your `kubernetes/terraform/environments/<env>` directory. This terraform represents the resources in your Kubernetes cluster, such as `cert-manager`, `external-dns`, Wireguard VPN, Nginx Ingress Controller, and other tools inside your cluster.
### `update-k8s-conf`
This updates your Kubernetes config by assuming the IAM role `admin-role`, allowing you to connect to your cluster using `kubectl` with administrator access. You can also assume other roles by providing the `ROLE` environment variable. Other default roles created are `developer` and `operator`.

## Others
The rest of the targets are mostly used for one-time operations, either for setup or teardown. The teardown commands are mostly for testing, as they will destroy your infrastructure, so be careful not to run them by accident.

### `apply-remote-state`
Sets up up your Terraform remote backend in an S3 bucket. All the other Terraform uses the remote backend to store their state files. The makefile will only run this step once per environment.

### `apply-secrets`
One-time setup of secrets for infrastructure. This make target also removes the local terraform state immediately after running. The makefile will only run this step once per environment.

### `pre-k8s`
Scripts to create resources required for subsequent steps. For example: creating a VPN private key, a database user, and JWKS keys for the user auth components.

### `post-apply-setup`
Scripts to create resources required for subsequent steps, for example creating a database user for your application and setting up the dev environment.

### `teardown*`
Mostly for development and testing, the teardown process follows a specific order, the reverse of how the resources were created. Much of it is non-reversible. Please see your repository's [Teardown] section for more information


[makefile]: https://github.com/commitdev/zero-aws-eks-stack/blob/main/templates/Makefile
[teardown]: https://github.com/commitdev/zero-aws-eks-stack/tree/main/templates#teardown