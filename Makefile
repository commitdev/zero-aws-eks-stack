ENV ?= staging

apply: apply-remote-state apply-secrets apply-env apply-k8s-utils

apply-remote-state:
	pushd terraform/bootstrap/remote-state; \
	terraform init; \
	terraform apply -var "environment=$(ENV)"

apply-secrets:
	pushd terraform/bootstrap/secrets; \
	terraform init; \
	terraform apply

apply-env:
	pushd terraform/environments/$(ENV); \
	terraform init; \
	terraform apply

apply-k8s-utils: update-k8s-conf
	pushd kubernetes/terraform/environments/$(ENV); \
	terraform init; \
	terraform apply

update-k8s-conf: eks --region <% index .Params `region` %> update-kubeconfig --name <% .Name %>-$(ENV)-<% index .Params `region` %>

teardown: teardown-k8s-utils teardown-env teardown-secrets teardown-remote-state

teardown-remote-state:
	pushd terraform/bootstrap/remote-state; \
	terraform destroy -auto-approve -var "environment=$(ENV)";

teardown-secrets:
	pushd terraform/bootstrap/secrets; \
	terraform destroy -auto-approve;

teardown-env:
	pushd terraform/environments/$(ENV); \
	terraform destroy -auto-approve;

teardown-k8s-utils:
	pushd kubernetes/terraform/environments/$(ENV); \
	terraform destroy;

.PHONY: apply apply-remote-state apply-secrets apply-env apply-k8s-utils teardown-k8s-utils teardown-env teardown-secrets teardown-remote-state
