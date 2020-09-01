#!/bin/sh
set -e

## Sendgrid
PROJECT_NAME=<% .Name %>
RANDOM_SEED=<% index .Params `randomSeed` %>
REGION=<% index .Params `region` %>
SENDGRID_ENDPOINT=https://api.sendgrid.com/v3/
SENDGRID_API_KEY=$(aws secretsmanager get-secret-value --region=${REGION} --secret-id=${PROJECT_NAME}-sendgrid-${RANDOM_SEED} --query "SecretString" | sed "s/\"//g")
PROJECT_DIR=..
DOMAIN_PREFIX=mail.

if [ "${ENVIRONMENT}" == "stage" ]; then
  SENDGRID_DOMAIN="${DOMAIN_PREFIX}<% index .Params `stagingHostRoot` %>"
elif [ "${ENVIRONMENT}" == "prod" ]; then
  SENDGRID_DOMAIN="${DOMAIN_PREFIX}<% index .Params `productionHostRoot` %>"
fi

if [ ! -z "${SENDGRID_API_KEY}" ]
then
  MATCHING_DOMAIN_COUNT=$(curl -XGET "${SENDGRID_ENDPOINT}whitelabel/domains" -H "Authorization:Bearer ${SENDGRID_API_KEY}" | jq -c "[ .[] | select(.domain == \"${SENDGRID_DOMAIN}\")] | length");
  ## If domain isnt found via that api_key
  if [ "${MATCHING_DOMAIN_COUNT}" -lt "1" ]; then
    curl -XPOST "${SENDGRID_ENDPOINT}whitelabel/domains" -H "Authorization:Bearer ${SENDGRID_API_KEY}" --data "{\"domain\": \"${SENDGRID_DOMAIN}\"}"
    ## This creates 2 files in your env's root containing
    ## terraform variables (sendgrid.auto.tfvars.json)
    curl -XGET "${SENDGRID_ENDPOINT}whitelabel/domains" -H "Authorization:Bearer ${SENDGRID_API_KEY}" | jq -r " .[] | select(.domain == \"${SENDGRID_DOMAIN}\")  | { sendgrid_enabled: true, sendgrid_domain_id : .id , sendgrid_cnames : ."dns" | map( [.host, .data] ) }" > ${PROJECT_DIR}/terraform/environments/${ENVIRONMENT}/sendgrid.auto.tfvars.json
  else
    echo "Domain already exist on sendgrid.";
  fi
fi
