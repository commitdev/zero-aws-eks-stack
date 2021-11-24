SHELL = /usr/bin/env bash
ENVIRONMENT ?= stage
PROJECT = <% .Name %>
ROLE ?= admin
export AWS_DEFAULT_REGION = <% index .Params `region` %>
export AWS_PAGER =
KUBE_CONTEXT := $(PROJECT)-$(ENVIRONMENT)-$(AWS_DEFAULT_REGION)

.EXPORT_ALL_VARIABLES:

apply: apply-remote-state apply-shared-remote-state apply-secrets apply-shared-env apply-env update-k8s-conf pre-k8s apply-k8s-utils post-apply-setup

apply-without-eks: apply-remote-state apply-shared-remote-state apply-secrets apply-shared-env apply-env post-apply-setup

apply-remote-state:
	aws s3 ls $(PROJECT)-$(ENVIRONMENT)-terraform-state > /dev/null 2>&1 || ( \
	cd terraform/bootstrap/remote-state && \
	terraform init && \
	terraform apply -var "environment=$(ENVIRONMENT)" $(AUTO_APPROVE) && \
	rm ./terraform.tfstate )

apply-shared-remote-state:
	aws s3 ls $(PROJECT)-shared-terraform-state > /dev/null 2>&1 || ( \
	cd terraform/bootstrap/remote-state && \
	terraform init && \
	terraform apply -var "environment=shared" $(AUTO_APPROVE) && \
	rm ./terraform.tfstate )

apply-secrets:
	aws secretsmanager describe-secret --secret-id "$(PROJECT)-$(ENVIRONMENT)-rds-<% index .Params `randomSeed` %>" > /dev/null 2>&1 || ( \
	cd terraform/bootstrap/secrets && \
	terraform init && \
	terraform apply $(AUTO_APPROVE) --var "sendgrid_api_key=${sendgridApiKey}" --var "slack_api_key=${notificationServiceSlackApiKey}" --var "twilio_account_id=${notificationServiceTwilioAccountId}"  --var "twilio_auth_token=${notificationServiceTwilioAuthToken}"&& \
	rm ./terraform.tfstate )

apply-shared-env:
	cd terraform/environments/shared; \
	terraform init && \
	terraform apply $(AUTO_APPROVE)

apply-env:
	cd terraform/environments/$(ENVIRONMENT); \
	terraform init && \
	terraform apply $(AUTO_APPROVE)

pre-k8s:
	cd scripts && sh pre-k8s.sh

apply-k8s-utils:
	cd kubernetes/terraform/environments/$(ENVIRONMENT) && \
	terraform init && \
	terraform apply $(AUTO_APPROVE)

update-k8s-conf:
	aws eks --region $(AWS_DEFAULT_REGION) update-kubeconfig --role "arn:aws:iam::<% index .Params `accountId` %>:role/$(PROJECT)-kubernetes-$(ROLE)-$(ENVIRONMENT)" --name $(KUBE_CONTEXT) --alias $(KUBE_CONTEXT)

post-apply-setup:
	cd scripts && sh post-apply.sh

teardown: teardown-k8s-utils teardown-env teardown-shared-env teardown-secrets teardown-remote-state teardown-shared-remote-state

teardown-remote-state:
	@echo "Deleting remote state is not reversible, are you sure you want to delete the resources? [y/N]:" ; read ans ; [ $${ans:-N} == "y" ] || exit 1
	aws dynamodb delete-table --region $(AWS_DEFAULT_REGION) --table-name $(PROJECT)-$(ENVIRONMENT)-terraform-state-locks
	aws s3 rm s3://$(PROJECT)-$(ENVIRONMENT)-terraform-state --recursive
	# TODO : This doesn't work because bucket versioning is enabled, we would need to loop through all versions of files and delete them manually
	aws s3 rb s3://$(PROJECT)-$(ENVIRONMENT)-terraform-state --force

teardown-shared-remote-state:
	@echo "Deleting shared remote state is not reversible, are you sure you want to delete the resources? [y/N]:" ; read ans ; [ $${ans:-N} == "y" ] || exit 1
	aws dynamodb delete-table --region $(AWS_DEFAULT_REGION) --table-name $(PROJECT)-shared-terraform-state-locks
	aws s3 rm s3://$(PROJECT)-shared-terraform-state --recursive
	# TODO : This doesn't work because bucket versioning is enabled, we would need to loop through all versions of files and delete them manually
	aws s3 rb s3://$(PROJECT)-shared-terraform-state --force

teardown-secrets:
	@echo "Deleting secrets is not reversible, are you sure you want to delete the secrets? [y/N]:" ; read ans ; [ $${ans:-N} == "y" ] || exit 1
	aws secretsmanager list-secrets --region $(AWS_DEFAULT_REGION) --query "SecretList[?Tags[?Key=='project' && Value=='$(PROJECT)']].[Name] | [0][0]" | xargs aws secretsmanager delete-secret --region $(AWS_DEFAULT_REGION) --secret-id || echo "Secret already removed"
	aws secretsmanager list-secrets --region $(AWS_DEFAULT_REGION) --query "SecretList[?Tags[?Key=='rds' && Value=='$(PROJECT)-$(ENVIRONMENT)']].[Name] | [0][0]" | xargs aws secretsmanager delete-secret --region $(AWS_DEFAULT_REGION) --secret-id || echo "Secret already removed"
	aws secretsmanager list-secrets --region $(AWS_DEFAULT_REGION) --query "SecretList[?Tags[?Key=='rds' && Value=='$(PROJECT)-$(ENVIRONMENT)-devenv']].[Name] | [0][0]" | xargs aws secretsmanager delete-secret --region $(AWS_DEFAULT_REGION) --secret-id || echo "Secret already removed"
	aws secretsmanager list-secrets --region $(AWS_DEFAULT_REGION) --query "SecretList[?Tags[?Key=='sendgrid' && Value=='$(PROJECT)']].[Name] | [0][0]" | xargs aws secretsmanager delete-secret --region $(AWS_DEFAULT_REGION) --secret-id || echo "Secret already removed"
	aws secretsmanager list-secrets --region $(AWS_DEFAULT_REGION) --query "SecretList[?Tags[?Key=='cf-keypair' && Value=='$(PROJECT)']].[Name] | [0][0]" | xargs aws secretsmanager delete-secret --region $(AWS_DEFAULT_REGION) --secret-id || echo "Secret already removed"
	aws secretsmanager list-secrets --region $(AWS_DEFAULT_REGION) --query "SecretList[?Tags[?Key=='wg' && Value=='$(PROJECT)-$(ENVIRONMENT)']].[Name] | [0][0]" | xargs aws secretsmanager delete-secret --region $(AWS_DEFAULT_REGION) --secret-id || echo "Secret already removed"
	aws secretsmanager list-secrets --region $(AWS_DEFAULT_REGION) --query "SecretList[?Tags[?Key=='oathkeeper-jwks' && Value=='$(PROJECT)-$(ENVIRONMENT)']].[Name] | [0][0]" | xargs aws secretsmanager delete-secret --region $(AWS_DEFAULT_REGION) --secret-id || echo "Secret already removed"
	aws secretsmanager list-secrets --region $(AWS_DEFAULT_REGION) --query "SecretList[?Tags[?Key=='application-secret' && Value=='$(PROJECT)-$(ENVIRONMENT)-$(PROJECT)']].[Name] | [0][0]" | xargs aws secretsmanager delete-secret --region $(AWS_DEFAULT_REGION) --secret-id || echo "Secret already removed"
	aws secretsmanager list-secrets --region $(AWS_DEFAULT_REGION) --query "SecretList[?Tags[?Key=='application-secret' && Value=='$(PROJECT)-$(ENVIRONMENT)-user-auth']].[Name] | [0][0]" | xargs aws secretsmanager delete-secret --region $(AWS_DEFAULT_REGION) --secret-id || echo "Secret already removed"
	aws iam list-role-policies --role-name $(PROJECT)-eks-cluster-creator --query "PolicyNames"   | jq -r ".[]" | xargs -n1 aws iam delete-role-policy --role-name $(PROJECT)-eks-cluster-creator --policy-name
	aws iam list-attached-role-policies --role-name $(PROJECT)-eks-cluster-creator --query "AttachedPolicies[].PolicyArn" | jq -r ".[]" | xargs -n1 aws iam detach-role-policy --role-name $(PROJECT)-eks-cluster-creator --policy-arn
	aws iam delete-role --role-name $(PROJECT)-eks-cluster-creator

teardown-env:
	cd terraform/environments/$(ENVIRONMENT) && \
	terraform refresh && \
	terraform destroy

teardown-shared-env:
	cd terraform/environments/shared && \
	terraform refresh && \
	terraform destroy

teardown-k8s-utils:
	cd kubernetes/terraform/environments/$(ENVIRONMENT) && \
	terraform refresh && \
	terraform destroy

.PHONY: apply apply-remote-state apply-secrets apply-env apply-k8s-utils teardown-k8s-utils teardown-env teardown-shared-env teardown-secrets teardown-remote-state teardown-shared-remote-state
