#!/bin/bash

#
# This script is to help user to create local AWS and Kubernetes configurations
# 
# You should have the following information ready before running:
# 1. your AWS user name
# 2. your AWS access key
# 3. your user role

IAM_USERNAME=$1
ROLE=$2
ENVIRONMENT=$3

# templated variables
AWS_ACCOUNT_ID=<% index .Params `accountId` %>
PROJECT=<% .Name %>
REGION=<% index .Params `region` %>

# common functions
function usage() {
  echo "  Usage:"
  echo "    $0 <iam_username> <role> <environment>"
  exit 1
}

function command_exist() {
  command -v ${1} >& /dev/null
}

function confirm_aws_profile() {
  aws configure --profile ${1} list >& /dev/null
}

function confirm_aws_identity() {
  AWS_PROFILE=${1} aws sts get-caller-identity >& /dev/null
}

function confirm_k8s_context() {
  [[ ${1} == $(kubectl config current-context) ]]
}

function warning_exit() {
  echo "WARNING: $1" && exit 2
}

# Start
echo "Your AWS account ID is ${AWS_ACCOUNT_ID}"
[[ -z "${ENVIRONMENT}" ]] && usage

echo "Starting setup ..."
echo

# Configure AWS profile
MY_AWS_PROFILE=${IAM_USERNAME}
## Check aws-cli installation
if ! command_exist aws
then
  warning_exit "command 'aws' not found: please visit https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html"
fi

## Checking & Configure AWS local profile
if ! confirm_aws_profile ${MY_AWS_PROFILE}; then
  echo "Setup new AWS profile: ${MY_AWS_PROFILE}"
  read -p "  AWS Access Key: " aws_access_key
  read -s -p "  AWS Secret Key:" aws_secret_key
  echo
  aws configure set --profile ${MY_AWS_PROFILE} aws_access_key_id $aws_access_key
  aws configure set --profile ${MY_AWS_PROFILE} aws_secret_access_key $aws_secret_key
  aws configure set --profile ${MY_AWS_PROFILE} region ${REGION}
fi
if ! confirm_aws_identity ${MY_AWS_PROFILE}; then
  warning_exit "Your profile not be able to setup, please check"
fi
echo "Confirmed your AWS profile '${MY_AWS_PROFILE}'"
echo

# Check & Configure K8S local context
if ! command_exist kubectl
then
  warinign_exit "command 'kubectl' not found. You can download it at https://kubernetes.io/docs/tasks/tools/install-kubectl/."
fi

NAMESPACE=${PROJECT}
MY_K8S_CONTEXT=${PROJECT}-${ENVIRONMENT}-${REGION}
if ! confirm_k8s_context ${MY_K8S_CONTEXT}; then
  # setup or switch context
  AWS_PROFILE=${MY_AWS_PROFILE} aws eks --region ${REGION} update-kubeconfig --role "arn:aws:iam::${AWS_ACCOUNT_ID}:role/${PROJECT}-kubernetes-${ROLE}-${ENVIRONMENT}" --name ${MY_K8S_CONTEXT} --alias ${MY_K8S_CONTEXT}
  if ! confirm_k8s_context ${MY_K8S_CONTEXT}; then
    warning_exit "Failed to setup your kubernetes context."
  fi
fi
echo "Confirmed your Kubernetes context '${MY_K8S_CONTEXT}'"
echo


# End
echo "Setup done successfully"
