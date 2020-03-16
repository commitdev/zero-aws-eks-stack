#!/bin/bash
ENV=${1:-staging}

# Setup the remote state storage
pushd terraform/environments/bootstrap;
terraform init;
terraform apply;
popd;

# Setup the secrets
pushd terraform/environments/bootstrap;
terraform init;
terraform apply;
popd;

# Setup the chosen environment
pushd terraform/environments/$ENV;
terraform init;
terraform apply;
popd;

# Setup the Kubernetes utilities
pushd kubernetes/terraform/environments/$ENV;
terraform init;
terraform apply;
popd;
