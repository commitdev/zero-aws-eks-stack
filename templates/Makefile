ENVIRONMENT ?= stage
PROJECT = <% .Name %>

apply: apply-remote-state apply-secrets apply-env apply-k8s-utils post-apply-setup

apply-remote-state:
	aws s3 ls $(PROJECT)-$(ENVIRONMENT)-terraform-state || (\
	cd terraform/bootstrap/remote-state && \
	terraform init && \
	terraform apply -var "environment=$(ENVIRONMENT)" $(AUTO_APPROVE) && \
	rm ./terraform.tfstate)

apply-secrets:
	aws iam list-access-keys --user-name $(PROJECT)-ci-user > /dev/null || (\
	cd terraform/bootstrap/secrets && \
	terraform init && \
	terraform apply $(AUTO_APPROVE) && \
	rm ./terraform.tfstate)

apply-env:
	cd terraform/environments/$(ENVIRONMENT); \
	terraform init && \
	terraform apply $(AUTO_APPROVE)

apply-k8s-utils: update-k8s-conf
	cd kubernetes/terraform/environments/$(ENVIRONMENT) && \
	terraform init && \
	terraform apply $(AUTO_APPROVE)

update-k8s-conf:
	aws eks --region <% index .Params `region` %> update-kubeconfig --name $(PROJECT)-$(ENVIRONMENT)-<% index .Params `region` %>

post-apply-setup:
	cd scripts && ENVIRONMENT=$(ENVIRONMENT) PROJECT=$(PROJECT) sh post-apply.sh

teardown: teardown-k8s-utils teardown-env teardown-secrets teardown-remote-state

teardown-remote-state:
	@echo "Deleting remote state is not reversible, are you sure you want to delete the resources? [y/N]:" && read ans && [ $${ans:-N} == y ] && \
	export AWS_PAGER='' && export AWS_DEFAULT_REGION=<% index .Params `region` %> && \
	aws s3 rm s3://$(PROJECT)-$(ENVIRONMENT)-terraform-state --recursive && \
	aws s3 rb s3://$(PROJECT)-$(ENVIRONMENT)-terraform-state --force && \
	aws dynamodb delete-table --region <% index .Params `region` %> --table-name $(PROJECT)-$(ENVIRONMENT)-terraform-state-locks

teardown-secrets:
	@echo "Deleting secrets is not reversible, are you sure you want to delete the secrets? [y/N]:" && read ans && [ $${ans:-N} == y ] && \
	export AWS_PAGER='' && export AWS_DEFAULT_REGION=<% index .Params `region` %> && \
	aws secretsmanager list-secrets --region <% index .Params `region` %> --query "SecretList[?Tags[?Key=='project' && Value=='$(PROJECT)']].[Name] | [0][0]" | xargs aws secretsmanager delete-secret --region <% index .Params `region` %> --secret-id && \
	aws secretsmanager list-secrets --region <% index .Params `region` %> --query "SecretList[?Tags[?Key=='rds' && Value=='$(PROJECT)-$(ENVIRONMENT)']].[Name] | [0][0]" | xargs aws secretsmanager delete-secret --region <% index .Params `region` %> --secret-id && \
	aws iam delete-access-key --user-name $(PROJECT)-ci-user --access-key-id $(shell aws iam list-access-keys --user-name $(PROJECT)-ci-user --query "AccessKeyMetadata[0].AccessKeyId" | sed 's/"//g') && \
	aws iam delete-user --user-name $(PROJECT)-ci-user

teardown-env:
	cd terraform/environments/$(ENVIRONMENT) && \
	terraform destroy

teardown-k8s-utils:
	cd kubernetes/terraform/environments/$(ENVIRONMENT) && \
	terraform destroy

.PHONY: apply apply-remote-state apply-secrets apply-env apply-k8s-utils teardown-k8s-utils teardown-env teardown-secrets teardown-remote-state
