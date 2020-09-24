SHELL = /usr/bin/env bash
ENVIRONMENT ?= stage
PROJECT = <% .Name %>
ROLE ?= admin
export AWS_DEFAULT_REGION = <% index .Params `region` %>
export AWS_PAGER =
KUBE_CONTEXT := $(PROJECT)-$(ENVIRONMENT)-$(AWS_DEFAULT_REGION)

apply: apply-remote-state apply-secrets apply-shared-env apply-env update-k8s-conf pre-k8s apply-k8s-utils post-apply-setup

apply-remote-state:
	aws s3 ls $(PROJECT)-$(ENVIRONMENT)-terraform-state > /dev/null 2>&1 || ( \
	cd terraform/bootstrap/remote-state && \
	terraform init && \
	terraform apply -var "environment=$(ENVIRONMENT)" $(AUTO_APPROVE) && \
	rm ./terraform.tfstate )

apply-secrets:
	aws iam list-access-keys --user-name $(PROJECT)-ci-user > /dev/null 2>&1 || ( \
	cd terraform/bootstrap/secrets && \
	terraform init && \
	terraform apply $(AUTO_APPROVE) && \
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
	@aws secretsmanager describe-secret --region $(AWS_DEFAULT_REGION) --secret-id $(PROJECT)-$(ENVIRONMENT)-vpn-wg-privatekey-<% index .Params `randomSeed` %> > /dev/null 2>&1 || ( \
	echo "Creating VPN private key..." && \
	kubectl run --context $(KUBE_CONTEXT) -i --tty zero-k8s-utilities --image=commitdev/zero-k8s-utilities:0.0.3 --restart=Never -- wg genkey | \
	xargs aws secretsmanager create-secret --region $(AWS_DEFAULT_REGION) --name $(PROJECT)-$(ENVIRONMENT)-vpn-wg-privatekey-<% index .Params `randomSeed` %> --description "Auto-generated Wireguard VPN private key" --secret-string && \
	kubectl delete --context $(KUBE_CONTEXT) pod/zero-k8s-utilities && \
	echo "Done VPN private key creation" )

apply-k8s-utils:
	cd kubernetes/terraform/environments/$(ENVIRONMENT) && \
	terraform init && \
	terraform apply $(AUTO_APPROVE)

update-k8s-conf:
	aws eks --region $(AWS_DEFAULT_REGION) update-kubeconfig --role "arn:aws:iam::<% index .Params `accountId` %>:role/$(PROJECT)-kubernetes-$(ROLE)-$(ENVIRONMENT)" --name $(KUBE_CONTEXT) --alias $(KUBE_CONTEXT)

post-apply-setup:
	cd scripts && ENVIRONMENT=$(ENVIRONMENT) PROJECT=$(PROJECT) sh post-apply.sh

teardown: teardown-k8s-utils teardown-env teardown-secrets teardown-remote-state

teardown-remote-state:
	@echo "Deleting remote state is not reversible, are you sure you want to delete the resources? [y/N]:" ; read ans ; [ $${ans:-N} == "y" ] || exit 1
	aws dynamodb delete-table --region $(AWS_DEFAULT_REGION) --table-name $(PROJECT)-$(ENVIRONMENT)-terraform-state-locks
	aws s3 rm s3://$(PROJECT)-$(ENVIRONMENT)-terraform-state --recursive
	# TODO : This doesn't work because bucket versioning is enabled, we would need to loop through all versions of files and delete them manually
	aws s3 rb s3://$(PROJECT)-$(ENVIRONMENT)-terraform-state --force

teardown-secrets:
	@echo "Deleting secrets is not reversible, are you sure you want to delete the secrets? [y/N]:" ; read ans ; [ $${ans:-N} == "y" ] || exit 1
	aws secretsmanager list-secrets --region $(AWS_DEFAULT_REGION) --query "SecretList[?Tags[?Key=='project' && Value=='$(PROJECT)']].[Name] | [0][0]" | xargs aws secretsmanager delete-secret --region $(AWS_DEFAULT_REGION) --secret-id || echo "Secret already removed"
	aws secretsmanager list-secrets --region $(AWS_DEFAULT_REGION) --query "SecretList[?Tags[?Key=='rds' && Value=='$(PROJECT)-$(ENVIRONMENT)']].[Name] | [0][0]" | xargs aws secretsmanager delete-secret --region $(AWS_DEFAULT_REGION) --secret-id || echo "Secret already removed"
	aws secretsmanager list-secrets --region $(AWS_DEFAULT_REGION) --query "SecretList[?Tags[?Key=='sendgrid' && Value=='$(PROJECT)']].[Name] | [0][0]" | xargs aws secretsmanager delete-secret --region $(AWS_DEFAULT_REGION) --secret-id || echo "Secret already removed"
	aws iam list-access-keys --user-name $(PROJECT)-ci-user --query "AccessKeyMetadata[0].AccessKeyId" --out text | xargs aws iam delete-access-key --user-name $(PROJECT)-ci-user --access-key-id
	aws iam delete-user --user-name $(PROJECT)-ci-user
	aws iam list-role-policies --role-name $(PROJECT)-eks-cluster-creator --query "PolicyNames"   | jq -r ".[]" | xargs -n1 aws iam delete-role-policy --role-name $(PROJECT)-eks-cluster-creator --policy-name
	aws iam list-attached-role-policies --role-name $(PROJECT)-eks-cluster-creator --query "AttachedPolicies[].PolicyArn" | jq -r ".[]" | xargs -n1 aws iam detach-role-policy --role-name $(PROJECT)-eks-cluster-creator --policy-arn
	aws iam delete-role --role-name $(PROJECT)-eks-cluster-creator

teardown-env:
	cd terraform/environments/$(ENVIRONMENT) && \
	terraform destroy

teardown-k8s-utils:
	cd kubernetes/terraform/environments/$(ENVIRONMENT) && \
	terraform destroy

.PHONY: apply apply-remote-state apply-secrets apply-env apply-k8s-utils teardown-k8s-utils teardown-env teardown-secrets teardown-remote-state
