#!/bin/sh

PROJECT=<% .Name %>
AWS_DEFAULT_REGION=<% index .Params `region` %>
RANDOM_SEED="<% index .Params `randomSeed` %>"
DATABASE_TYPE=<% index .Params `database` %>
ENVIRONMENT=stage  # only apply to Staging environment

## Creating each member in developer IAM group a dev-database
## name: john-doe -> dbname: dev_johndoe
DEV_DB_LIST=$(aws iam get-group --group-name ${PROJECT}-developer-${ENVIRONMENT} | jq -r '"dev_" + .Users[].UserName' | tr '\n' ' ')
if [[ -z "${DEV_DB_LIST}" ]]; then
    echo "$0: No developers available yet, skip."
    exit 0
fi

DEV_DB_SECRET_NAME=${PROJECT}-${ENVIRONMENT}-rds-${RANDOM_SEED}-devenv
aws secretsmanager describe-secret --region ${AWS_DEFAULT_REGION} --secret-id ${DEV_DB_SECRET_NAME} > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
    DEV_DB_SECRET=$(aws secretsmanager get-secret-value --region=${AWS_DEFAULT_REGION} --secret-id ${DEV_DB_SECRET_NAME} | jq -r ".SecretString")
    REGION=${AWS_DEFAULT_REGION} \
    SEED=${RANDOM_SEED} \
    PROJECT_NAME=${PROJECT} \
    ENVIRONMENT=${ENVIRONMENT} \
    NAMESPACE=${PROJECT} \
    DATABASE_TYPE=${DATABASE_TYPE} \
    DATABASE_NAME="${DEV_DB_LIST}" \
    SECRET_NAME=devenv-${PROJECT} \
    USER_NAME=dev${PROJECT} \
    USER_PASSWORD=${DEV_DB_SECRET} \
    CREATE_SECRET=secret-application.json.tpl \
    sh ./create-db-user.sh
fi
