#!/bin/sh
ZERO_K8S_UTILS_VERSION=0.0.3
OATHKEEPER_VERSION=v0.38.4-beta.1-alpine

VPN_SECRET_NAME=${PROJECT}-${ENVIRONMENT}-vpn-wg-privatekey-<% index .Params `randomSeed` %>
OATHKEEPER_SECRET_NAME=${PROJECT}-${ENVIRONMENT}-oathkeeper-jwks-<% index .Params `randomSeed` %>

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
<% end %>
