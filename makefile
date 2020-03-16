ENV ?= staging

apply: apply-remote-state apply-secrets apply-env apply-k8s-utils

apply-remote-state: 
	pushd terraform/bootstrap/remote-state; \
	terraform init; \
	terraform apply

apply-secrets: 
	pushd terraform/bootstrap/secrets; \
	terraform init; \
	terraform apply

apply-env: 
	pushd terraform/environments/$(ENV); \
	terraform init; \
	terraform apply

apply-k8s-utils:
	pushd kubernetes/terraform/environments/$(ENV); \
	terraform init; \
	terraform apply

.PHONY: apply apply-remote-state apply-secrets apply-env apply-k8s-utils
