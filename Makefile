SHELL := /bin/bash
CREATE_DB_DEFAULT_USER := $(shell kubectl -n ${PROJECT_NAME} get secrets ${PROJECT_NAME} > /dev/null 2>&1; echo $$?)

DEV_DB_LIST := $(shell aws iam get-group --group-name ${PROJECT_NAME}-developer-${ENVIRONMENT} | jq -r .Users[].UserName | sed 's/^/dev/' | tr '\n' ' ')
DEV_DB_SECRET := $(shell aws secretsmanager list-secrets --region ${region} --query "SecretList[?Tags[?Key=='rds' && Value=='$(PROJECT_NAME)-$(ENVIRONMENT)-devenv']].[Name] | [0][0]" | xargs aws secretsmanager get-secret-value --region=${region} --secret-id | jq -r ".SecretString" || echo)

run: make-apply create-application-default-user create-application-dev-user create-auth-user

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
	DATABASE_LIST=${PROJECT_NAME} \
	USER_NAME=${PROJECT_NAME} \
	USER_PASSWORD= \
	CREATE_SECRET=secret-application.yml.tpl \
	CREATE_DB_POD=deployment-db-test.yml.tpl \
	sh ./db-ops/create-db-user.sh || echo

create-application-dev-user:
	[[ "${ENVIRONMENT}" == "stage" && -n "${IAM_DEV_ENV_USERS}" && -n "${DEV_DB_SECRET}" ]] && \
	REGION=${region} \
	SEED=${randomSeed} \
	PROJECT_NAME=${PROJECT_NAME} \
	ENVIRONMENT=${ENVIRONMENT} \
	NAMESPACE=${PROJECT_NAME} \
	DATABASE_TYPE=postgres \
	DATABASE_LIST="${DEV_DB_LIST}" \
	USER_NAME=dev${PROJECT_NAME} \
	USER_PASSWORD=${DEV_DB_SECRET} \
	CREATE_SECRET= \
	CREATE_DB_POD= \
	sh ./db-ops/create-db-user.sh || echo

create-auth-user:
	[[ "${CREATE_DB_DEFAULT_USER}" != "0" && "${userAuth}" == "yes" ]] && \
	REGION=${region} \
	SEED=${randomSeed} \
	PROJECT_NAME=${PROJECT_NAME} \
	ENVIRONMENT=${ENVIRONMENT} \
	NAMESPACE=user-auth \
	DATABASE_TYPE=${database} \
	DATABASE_LIST=user_auth \
	USER_NAME=kratos \
	USER_PASSWORD= \
	CREATE_SECRET=secret-user-auth.yml.tpl \
	CREATE_DB_POD=deployment-db-test.yml.tpl \
	sh ./db-ops/create-db-user.sh || echo

summary:
	@echo "zero-aws-eks-stack:"
	@echo "- Repository URL: ${REPOSITORY}"
	@echo "- To see your kubernetes clusters, run: 'kubectl config get-contexts'"
	@echo "- To switch to a cluster, use the following commands:"
	@echo $(shell [[ "${ENVIRONMENT}" =~ "production" ]] && echo "- for production use: kubectl config use-context $(shell kubectl config get-contexts -o name | grep ${PROJECT_NAME}-production)")
	@echo $(shell [[ "${ENVIRONMENT}" =~ "staging" ]] && echo "- for staging use: kubectl config use-context $(shell kubectl config get-contexts -o name | grep ${PROJECT_NAME}-staging)")
	@echo "- To inspect the selected cluster, run 'kubectl get node,service,deployment,pods'"
