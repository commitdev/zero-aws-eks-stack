#!/bin/sh
ZERO_K8S_UTILS_VERSION=0.0.3
OATHKEEPER_VERSION=v0.38.4-beta.1-alpine
KUBE_CONTEXT=${PROJECT}-${ENVIRONMENT}-${AWS_DEFAULT_REGION}
RANDOM_SEED="<% index .Params `randomSeed` %>"

VPN_SECRET_NAME=${PROJECT}-${ENVIRONMENT}-vpn-wg-privatekey-${RANDOM_SEED}
OATHKEEPER_SECRET_NAME=${PROJECT}-${ENVIRONMENT}-oathkeeper-jwks-${RANDOM_SEED}

# Create VPN private key if the secret doesn't already exist
aws secretsmanager describe-secret --region ${AWS_DEFAULT_REGION} --secret-id ${VPN_SECRET_NAME} > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    echo "Creating VPN private key..."
    secret=$(kubectl run --rm --quiet --attach=true --context ${KUBE_CONTEXT} zero-k8s-utilities --image=commitdev/zero-k8s-utilities:${ZERO_K8S_UTILS_VERSION} --restart=Never -- wg genkey)
    aws secretsmanager create-secret --region ${AWS_DEFAULT_REGION} --name ${VPN_SECRET_NAME} --description "Auto-generated Wireguard VPN private key" --tags "[{\"Key\":\"wg\",\"Value\":\"${PROJECT}-${ENVIRONMENT}\"}]" --secret-string "${secret}"

    if [[ $? -eq 0 ]]; then
        echo "Done VPN private key creation"
    fi
fi

<% if eq (index .Params `userAuth`) "yes" %>
# Create oathkeeper JWKS file if the secret doesn't already exist
aws secretsmanager describe-secret --region ${AWS_DEFAULT_REGION} --secret-id ${OATHKEEPER_SECRET_NAME} > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    echo "Creating Oathkeeper JWKS file..."
    secret=$(kubectl run --rm --quiet --attach=true --context ${KUBE_CONTEXT} oathkeeper --image=oryd/oathkeeper:${OATHKEEPER_VERSION} --restart=Never -- credentials generate --alg RS256)
    aws secretsmanager create-secret --region ${AWS_DEFAULT_REGION} --name ${OATHKEEPER_SECRET_NAME} --description "Auto-generated Oathkeeper JWKS file" --tags "[{\"Key\":\"oathkeeper-jwks\",\"Value\":\"${PROJECT}-${ENVIRONMENT}\"}]" --secret-string "${secret}"
    if [[ $? -eq 0 ]]; then
        echo "Done Oathkeeper JWKS file creation..."
    fi
fi

kubectl --context ${KUBE_CONTEXT} -n user-auth get secrets ${PROJECT} > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    REGION=${AWS_DEFAULT_REGION} \
    SEED=${RANDOM_SEED} \
    PROJECT_NAME=${PROJECT} \
    ENVIRONMENT=${ENVIRONMENT} \
    NAMESPACE=user-auth \
    DATABASE_TYPE=<% index .Params `database` %> \
    DATABASE_NAME=user_auth \
    SECRET_NAME=user-auth \
    USER_NAME=kratos \
    CREATE_SECRET=secret-user-auth.yml.tpl \
    <%- if ne (index .Params `sendgridApiKey`) "" %>
    SMTP_URI=smtps://apikey:${sendgridApiKey}@smtp.sendgrid.net:465 \
    <%- else %>
    SMTP_URI=smtps://no-value-specified:25 \
    <%- end %>
    sh ./create-db-user.sh
fi

<% end %>
