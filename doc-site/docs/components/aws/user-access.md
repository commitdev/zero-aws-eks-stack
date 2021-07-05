---
title: User access
sidebar_label: User access
sidebar_position: 1
---

## Notable Roles and Users created:
### Users:
`<project-name>-ci-user`

### Roles:

#### `<project-name>-eks-cluster-creator`:
When creating an EKS cluster, the user who does the creation is assigned special access to be able to connect to the cluster to do the initial setup.
This can cause issues with terraform where if another user tries to run the terraform they may not have access to the cluster since they are not the initial user.

#### `<project-name>-kubernetes-admin-[env]`:
Env can be one of: `prod`, `stage`
This role allows accessing Kubernetes cluster as an admin, used in the life cycle to apply changes when using null-resource and local-exec.

#### `<project-name>-kubernetes-[roles]-[env]`:
- Roles can be one of: `operator`, `deployer`, `developer`
- Env can be one of: `prod`, `stage`

## Adding Team members
[See detailed guide][link-to-user-management-doc] for how to manage users

## Controlling access to Kubernetes
When team members are added to the team in terraform `shared` module, they will be able to assume the following roles to interact with the Kubernetes cluster. This is setup for you per environment so you can customize the fine grain access control per environment([stage][k8s-access-stage], [prod][k8s-access-prod]).


[link-to-user-management-doc]: ../../guides/user-management

[k8s-access-stage]: https://github.com/commitdev/zero-aws-eks-stack/blob/main/templates/terraform/environments/stage/user_access.tf
[k8s-access-prod]: https://github.com/commitdev/zero-aws-eks-stack/blob/main/templates/terraform/environments/prod/user_access.tf