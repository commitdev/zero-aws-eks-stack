#!/bin/sh

RANDOM_SEED="<% index .Params `randomSeed` %>"

<% if ne (index .Params `loggingType`) "kibana" %># <% end %>source elasticsearch-logging.sh

aws secretsmanager --region "$AWS_DEFAULT_REGION" describe-secret --secret-id "${PROJECT}/kubernetes/${ENVIRONMENT}/${PROJECT}" > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    REGION=${AWS_DEFAULT_REGION} \
    SEED=${RANDOM_SEED} \
    PROJECT_NAME=${PROJECT} \
    ENVIRONMENT=${ENVIRONMENT} \
    NAMESPACE=${PROJECT} \
    DATABASE_TYPE=<% index .Params `database` %> \
    DATABASE_NAME=${PROJECT} \
    SECRET_NAME=${PROJECT} \
    USER_NAME=${PROJECT} \
    CREATE_SECRET=secret-application.json.tpl \
    sh ./create-db-user.sh
fi

# Create dev environment on Staging for developers
if [[ ${ENVIRONMENT} == "stage" ]]; then
    sh ./create-dev-env.sh
fi
