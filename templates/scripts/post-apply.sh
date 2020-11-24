#!/bin/sh
set -e

RANDOM_SEED="<% index .Params `randomSeed` %>"

<% if ne (index .Params `loggingType`) "kibana" %># <% end %>source elasticsearch-logging.sh

shell kubectl -n ${PROJECT} get secrets ${PROJECT} > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    REGION=${AWS_DEFAULT_REGION} \
    SEED=${RANDOM_SEED} \
    PROJECT_NAME=${PROJECT} \
    ENVIRONMENT=${ENVIRONMENT} \
    NAMESPACE=${PROJECT} \
    DATABASE_TYPE=<% index .Params `database` %> \
    DATABASE_NAME=${PROJECT} \
    USER_NAME=${PROJECT} \
    CREATE_SECRET=secret-application.yml.tpl \
    sh ./create-db-user.sh || echo "Skipping database credential creation - credentials already exist"
fi
