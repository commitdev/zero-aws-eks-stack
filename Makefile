SHELL := /bin/bash

run: create-db-user
	cd $(PROJECT_DIR) && AUTO_APPROVE="-auto-approve" make

create-db-user:
	kubectl -n ${PROJECT_NAME} get secrets ${PROJECT_NAME} > /dev/null 2>&1 || ( \
	export REGION=${region}; \
	export SEED=${randomSeed}; \
	export PROJECT_NAME=${PROJECT_NAME}; \
	export ENVIRONMENT=${ENVIRONMENT}; \
	export DATABASE=${database}; \
	sh ./db-ops/create-db-user.sh )

summary:
	@echo "zero-aws-eks-stack:"
	@echo "- Repository URL: ${REPOSITORY}"
	@echo "- To see your kubernetes clusters, run: 'kubectl config get-contexts'"
	@echo "- To switch to a cluster, use the following commands:"
	@echo $(shell [[ "${ENVIRONMENT}" =~ "production" ]] && echo "- for production use: kubectl config use-context $(shell kubectl config get-contexts -o name | grep ${PROJECT_NAME}-production)")
	@echo $(shell [[ "${ENVIRONMENT}" =~ "staging" ]] && echo "- for staging use: kubectl config use-context $(shell kubectl config get-contexts -o name | grep ${PROJECT_NAME}-staging)")
	@echo "- To inspect the selected cluster, run 'kubectl get node,service,deployment,pods'"
