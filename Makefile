SHELL := /bin/bash
CREATE_DB_DEFAULT_USER := $(shell kubectl -n ${PROJECT_NAME} get secrets ${PROJECT_NAME} > /dev/null 2>&1; echo $$?)
IAM_DEV_ENV_USERS := $(shell aws iam get-group --group-name ${PROJECT_NAME}-developer-${ENVIRONMENT} | jq -r .Users[].UserName)
CREATE_DB_DEV_USERS := $(shell for u in ${IAM_DEV_ENV_USERS}; do kubectl -n ${PROJECT_NAME} get secrets dev-$${u} > /dev/null 2>&1; [[ "$$?" != "0" ]] && echo $${u}; done)
#CREATE_DB_DEV_USERS := $(shell echo ${IAM_DEV_ENV_USERS})

run: make-apply create-application-user create-application-dev-user create-auth-user

make-apply:
	cd $(PROJECT_DIR) && AUTO_APPROVE="-auto-approve" make

create-application-default-user:
	[[ "${CREATE_DB_DEFAULT_USER}" != "0" ]] && \
	REGION=${region} \
	SEED=${randomSeed} \
	PROJECT_NAME=${PROJECT_NAME} \
	ENVIRONMENT=${ENVIRONMENT} \
	NAMESPACE=${PROJECT_NAME} \
	DATABASE_TYPE=${database} \
	DATABASE_NAME=${PROJECT_NAME} \
	USER_NAME=${PROJECT_NAME} \
	CREATE_SECRET=secret-application.yml.tpl \
	sh ./db-ops/create-db-user.sh || echo

create-application-dev-user:
	for u in ${CREATE_DB_DEV_USERS}; do \
	REGION=${region} \
	SEED=${randomSeed} \
	PROJECT_NAME=${PROJECT_NAME} \
	ENVIRONMENT=${ENVIRONMENT} \
	NAMESPACE=${PROJECT_NAME} \
	DATABASE_TYPE=${database} \
	CREATE_SECRET=secret-application-dev.yml.tpl \
	DATABASE_NAME=dev-$${u} \
	USER_NAME=dev-$${u} \
	sh ./db-ops/create-db-user.sh || echo; \
	done

create-auth-user:
	[[ "${CREATE_DB_DEFAULT_USER}" != "0" && "${userAuth}" == "yes" ]] && \
	REGION=${region} \
	SEED=${randomSeed} \
	PROJECT_NAME=${PROJECT_NAME} \
	ENVIRONMENT=${ENVIRONMENT} \
	NAMESPACE=user-auth \
	DATABASE_TYPE=${database} \
	DATABASE_NAME=user_auth \
	USER_NAME=kratos \
	CREATE_SECRET=secret-user-auth.yml.tpl \
	sh ./db-ops/create-db-user.sh || echo

summary:
	@echo "zero-aws-eks-stack:"
	@echo "- Repository URL: ${REPOSITORY}"
	@echo "- To see your kubernetes clusters, run: 'kubectl config get-contexts'"
	@echo "- To switch to a cluster, use the following commands:"
	@echo $(shell [[ "${ENVIRONMENT}" =~ "production" ]] && echo "- for production use: kubectl config use-context $(shell kubectl config get-contexts -o name | grep ${PROJECT_NAME}-production)")
	@echo $(shell [[ "${ENVIRONMENT}" =~ "staging" ]] && echo "- for staging use: kubectl config use-context $(shell kubectl config get-contexts -o name | grep ${PROJECT_NAME}-staging)")
	@echo "- To inspect the selected cluster, run 'kubectl get node,service,deployment,pods'"
