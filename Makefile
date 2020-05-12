ENV ?= staging

apply: apply-remote-state apply-secrets apply-env apply-k8s-utils

## remove state file only if exit code 0 from terraform apply
apply-remote-state:
	pushd terraform/bootstrap/remote-state && \
	terraform init && \
	terraform apply -var "environment=$(ENV)" && \
	rm ./terraform.tfstate

apply-secrets:
	pushd terraform/bootstrap/secrets && \
	terraform init && \
	terraform apply && \
	rm ./terraform.tfstate

apply-env:
	pushd terraform/environments/$(ENV); \
	terraform init && \
	terraform apply

apply-k8s-utils: update-k8s-conf
	pushd kubernetes/terraform/environments/$(ENV) && \
	terraform init && \
	terraform apply

update-k8s-conf:
	aws eks --region <% index .Params `region` %> update-kubeconfig --name <% .Name %>-$(ENV)-<% index .Params `region` %>

teardown: teardown-k8s-utils teardown-env teardown-secrets teardown-remote-state

teardown-remote-state:
	export AWS_PAGER='' && \
	aws s3 rb s3://<% .Name %>-$(ENV)-terraform-state --force && \
	aws dynamodb delete-table --table-name <% .Name %>-$(ENV)-terraform-state-locks

teardown-secrets:
	export AWS_PAGER='' && \
	aws secretsmanager list-secrets --query "SecretList[?Tags[?Key=='project' && Value=='<% .Name %>']].[Name] | [0][0]" | xargs aws secretsmanager delete-secret --secret-id && \
	aws iam delete-access-key --user-name <% .Name %>-ci-user --access-key-id $(shell aws iam list-access-keys --user-name <% .Name %>-ci-user --query "AccessKeyMetadata[0].AccessKeyId" | sed 's/"//g') && \
	aws iam delete-user --user-name <% .Name %>-ci-user

teardown-env:
	pushd terraform/environments/$(ENV) && \
	terraform destroy

teardown-k8s-utils:
	pushd kubernetes/terraform/environments/$(ENV) && \
	terraform destroy

.PHONY: apply apply-remote-state apply-secrets apply-env apply-k8s-utils teardown-k8s-utils teardown-env teardown-secrets teardown-remote-state
