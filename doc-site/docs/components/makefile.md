---
title: Explaining the Makefile in your repository
sidebar_label: Makefile Lifecycle
sidebar_position: 2
---

## Overview
The [Makefile] shipped with your repository is the controller of your infrastructure, it defines the order of execution during the `apply` make target.

The [Makefile] is idempotent by design, meaning when `zero apply` runs it will attempt to reach the same final state every time it is executed. Therefore if the script determines a resources have previously created it will skip the creation when ran again, and making if `zero apply` can be re-ran after initial setup.

## Targets Explained
Some of the steps are used for initializing the infrastructure, and some steps can also be used for updating and maintaining the infrastructure.

All the targets can be ran with `ENVIRONMENT=<prod|stage>` to target the corresponding environment, and defaults to `stage`

## Helpful targets for day-to-day use

### `apply-shared-env`
The runs `terraform apply` in your `terraform/environments/shared` folder and is responsible for resources shared between both stage/prod, for example IAM users and groups.
### `apply-env`
The runs `terraform apply` in your `terraform/environments/<env>` folder and  represents the infrastructure resources in your AWS, VPC, S3 buckets, and the creation of your EKS cluster.
### `apply-k8s-utils`
The runs `terraform apply` in your `terraform/environments/shared` folder and  represents the resources in Kubernetes Cluster, such as Cert-manager, externalDNS, Wireguard VPN, and other tools inside your cluster.
### `update-k8s-conf`
This updates your kubernetes config using assuming `admin-role`, allowing you to connect to your Kubernetes cluster as the Kubernetes administrator.

## Others
The rest of the targets are mostly used for one-time operations, either for setup or teardown.

### `apply-remote-state`
Setups up your remote-backend in an S3 bucket, all the other terraform uses the remote-backend setup as their backend.

### `apply-secrets`
Sets up secrets for infrastructure, the make target also removes the terraform state immediately after, because the secrets only needs to be created once for both environment and will create once no matter which environment is provisioned first.

### `pre-k8s`
Scripts to create resources required for sub-sequence state, for example creating VPN private key, an Auth Database user, and JWK keys for the user auth components.

### `post-apply-setup`
Scripts to create resources required for sub-sequence state, for example creating Application Database user and Dev-environment setup.

### `teardown*`
The teardown follows specific order and you will need to follow that same order and much of it is non-reversible. Please see your repository's [Teardown] section for more information


[makefile]: https://github.com/commitdev/zero-aws-eks-stack/blob/main/templates/Makefile
[teardown]: https://github.com/commitdev/zero-aws-eks-stack/tree/main/templates#teardown