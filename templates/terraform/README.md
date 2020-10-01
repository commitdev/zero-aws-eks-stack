## Guidelines & Style Convention Summary

- All Terraform configuration should be formatted with `terraform fmt` before being accepted into this repository.
- This repository is Terraform version >= 0.13, as such, leverage features from this release whenever possible.
    See https://www.terraform.io/upgrade-guides/0-13.html for more information.
- Leverage community-maintained Terraform modules whenever possible.
- Attempt to minimize duplication whenever possible, but only within reason -- sometimes duplication is an acceptable solution.
- Whenever possible, define the types of variables.


### Environment Conventions

- `terraform/environments/` contains the configuration for specific environments (staging, production, etc.)
- All environments should contain the following:

    `main.tf`: Top level terraform configuration file that instantiates the `environment` module and provides configuration values.

- Configuration should be pushed "top->down" from the `environment` module to it's submodules.
- If there is some feature that is specific to a single environment it could be put into another `.tf` file in the `environments/<env>` directory, but as much as possible, try to work with reusable modules instead.
- Many modules are provided from the Zero terraform registry. These specify a version number. To take advantage of a new fix or feature in one of these modules, just change the version number and run `terraform init` to pull in the new code.


### The Environment Module

- The `environment` module can be considered the top-level module, all other modules are imported from this module.
- Environment-specific variables should be exposed via the `variables.tf` file in this module, where they will be set from within the appropriate environment in the `environments/` directory.
- The `environment` module contains the following:

    `main.tf`: Module entrypoint where instantiation of resources happens.
    `provider.tf`: Provider configuration.
    `variables.tf`: Environment-specific variables are declared here.
    `versions.tf`: Terraform version information.


### Module Conventions

- Modules should be used to provide functionality that will be used in multiple environments. The `environment` module is the place where all shared modules are used.
- All modules should contain the following:

    `README.md`: A description of the module.
    `main.tf`: Module entrypoint where instantiation of resources happens.
    `variables.tf`: Module variables.
    `outputs.tf`: Output values.
    `files/`: Any non-Terraform files required by the module.

- All module variables must have a description.
- Again, leverage community-maintained Terraform modules whenever possible.
- Avoid writing a module that is simply a wrapper of a Terraform resource unless absolutely necessary.

## Directory Structure

```
    README.md
    environments/
        prod/
            main.tf
        stage/
            main.tf
    modules/
        environment/
            ...
        <module-a>/
            files/
            scripts/
            main.tf
            outputs.tf
            variables.tf
        <module-n>/
        ...
```

## AWS Guidelines

- TODO: Identity/Access Management (IAM) Guidelines

## Kubernetes Guidelines

- When to use the Terraform Kuberenetes Provider and when to use manifests?

    - Use the Terraform Kubernetes Provider (`provider "kubernetes"`) whenever you are provisioning a resource that could be considered relatively static (think Ingress, RoleBinding, ClusterRoleBinding, etc).

    - Use conventional Kubernetes manifests / `kubectl` when provisioning resources that could be considered dynamic (think Deployments).

## Application

 1. Set up a profile for your project with your credentials in a specific profile in `~/.aws/credentials` and then export the following env var:
 `export AWS_PROFILE=<project_name>`

 2. Run the following from the appropriate environment directory under `environments/`:

 ```
 environment/stage$ terraform init
 environment/stage$ terraform plan
 ```

## To use kubectl with the created EKS cluster:

 Exchange your aws credentials for kubernetes credentials.
 This will add a new context to your kubeconfig.
 In the root of the project, run:
 ```
 make update-k8s-conf
 ```

If a user has a role other than admin (dev, operations, etc.) they can specify it here as well: 
```
 ROLE=<role> make update-k8s-conf
 ```

## User Access

You may want to give memebers of your team access to the infrastructure.
Individual roles and permissions are defined in `environments/<env>/user_access.tf`, these will define the amount of access a user in that role has to both AWS and Kubernetes.

 1. Add users in `environments/shared/main.tf` and specify the role they should have in each environment, then run:
```
make apply-shared-env
```

 2. To do the assignment of users to roles in each environment, you must run this for each:
```
ENVIRONENT=<env> make apply-env
```
This should detect that there was a new user created, and put them into the necessary group.

 3. To create initial temporary password for users, you may run:
```
script/setup-user-password.sh -g <group name>  # for users under a group
or
script/setup-user-password.sh -u <user name>   # for individual user

```

New users need to setup local configurations for resoruce access, run:
```
script/setup-user-access.sh <user name> <role> <environment>
```


## Upgrading an EKS Cluster

Occasionally you may need to upgrade an EKS cluster. This is usually a pretty painless process, and there’s a ton of documentation online about it.

As part of this process you will need to upgrade the cluster itself, and some core components. Kubernetes has various applications that run as deployments or daemonsets in the `kube-system` namespace like `coredns`, `kube-proxy` and the AWS VPC CNI provider called `aws-node`.

This document has great instructions on upgrading all of the different pieces, including listing the appropriate versions of the core components for each version of Kubernetes.

[https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html](https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html)

When doing this from terraform you should be able to go into the tf and change the version of the cluster. It should start the upgrade process, rather than tearing down the cluster and rebuilding it. This will make the cluster inaccessible through the AWS console for about 20 minutes, ***though everything in the cluster should continue to work normally, serve traffic, etc.***

The process should be:

- Update the API version number in terraform
- Update the AMI for the ASG to the AMI for the corresponding version of EKS in eks.tf and apply terraform
    - See this page: [https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html)
    - This should update the worker group, but not affect any of the running nodes
- Update any core components if necessary, as mentioned in the aws update-cluster documentation
- Run terraform apply
- Drain and remove the old nodes from the cluster. New ones will come up in their place with the new AMI
    - `kubectl get nodes`
    - `kubectl cordon <node name>`
    - `kubectl drain <node name>`
    - Then terminate the instance in AWS Console
- (The cordon command stops new pods from being scheduled on a node, the drain command evicts all pods from a node and schedules them elsewhere.)
- Do the drain/delete process with one node at a time. Wait for a new node to be available before running the process on a second one. This will prevent any traffic from being lost.

Done!

<% if eq (index .Params `loggingType`) "kibana" %>
## Kibana and Elasticsearch index Management

After creating the AWS Elasticsearch cluster to hold log data it’s a good idea to create index policies to control how data ages over time.

Typically you will want different policies on Staging and Production, as staging will probably have less restrictions about availability and speed, and more retained data increases cost.

You can view these in Kibana's Index Management UI by clicking on the "IM" tab, but some default indices and lifecycles are automatically created. You can see the policies that were created in [scripts/files/](../scripts/files/)
If you want to change these policies you can update the json files as necessary and then run `sh scripts/elasticsearch-logging.sh`

### Maintenance

Over the long term, policies like this should prevent indices from growing too big for the system to be able to store, but if the policies or amount of data per day change over time it may be necessary to investigate the state of the system to tweak some of these values.

The most likely limitations to hit will be size on disk and number of shards.

**Number of shards** will most likely stay at a stable amount, regardless of log volume, unless the policies are changed, as the policies control the number of indices that will be maintained, and each index has a set number of shards.

To see the current number of shards you can execute the stats query through the Kibana dev UI:

```
GET /_stats
result:
{ "_shards" : { "total" : 471, "successful" : 240, "failed" : 0 }, ...
}
```

The number of shards can’t exceed 1000 per node. If it reaches that limit, new indices can’t be created and log ingestion will stop until previous indices have been deleted.

**Size on disk** may fluctuate more than the number of shards because it is affected by the log volume. Old indices will be removed which will clear space every day, but it’s possible that the log volume will increase faster than the rate old logs are deleted, in which case the disk may fill up.

The best place to view this is the AWS console for Elasticsearch.

If the free space gets too low, the EBS volume can be resized by changing the value in Terraform, and it will be resized with no downtime.
<% end %>
