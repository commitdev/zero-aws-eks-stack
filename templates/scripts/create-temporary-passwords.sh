#!/bin/bash

#
# This script to help Admin create password for new users
#  - automatically detect users in group "console-allowed" and skip the ones who already have login profile
#

AWS_ACCOUNT_ID=<% index .Params `accountId` %>

function usage() {
  echo "  Usage:"
  echo "    $0 -g|--group <group> -u|--user <user> -h"
  exit 1
}

function warning_exit() {
  echo "WARNING: $1"
  exit 2
}

function confirm() {
  local _prompt _default _response
 
  if [ "$1" ]; then _prompt="$1"; else _prompt="Are you sure"; fi
  _prompt="$_prompt [y/n] ?"
 
  # Loop forever until the user enters a valid response (Y/N or Yes/No).
  while true; do
    read -r -p "$_prompt " _response
    case "$_response" in
      [Yy][Ee][Ss]|[Yy]) # Yes or Y (case-insensitive).
        return 0
        ;;
      [Nn][Oo]|[Nn])  # No or N.
        return 1
        ;;
      *) # Anything else (including a blank) is invalid.
        ;;
    esac
  done
}

# Parse args
while getopts 'g:u:h' c
do
  case $c in
    h) usage ;;
    g) INPUT_GROUP=$OPTARG ;;
    u) INPUT_USER=$OPTARG ;;
  esac
done

[[ -z "$INPUT_GROUP" ]] && [[ -z "${INPUT_USER}" ]] && INPUT_GROUP="console-allowed" # set default group

[[ -n "$INPUT_GROUP" ]] && [[ -n "${INPUT_USER}" ]] && warning_exit "Can not input both group and user togeher"

# Start
echo "Your current AWS account is ${AWS_ACCOUNT_ID}"
echo

# Collect users in this group without password
function set_temp_password() {
    user=$1
    tpass=$(aws secretsmanager get-random-password --password-length 16 --require-each-included-type --output text)
    aws iam create-login-profile --user-name $user --password "$tpass" --password-reset-required >& /dev/null
    roles=$(aws iam list-groups-for-user --user-name $user | jq '.Groups[] | select(.Path == "/users/") | .GroupName' | tr -d "\"" | tr "\n" " ")
    echo "  username:\"$tuser\", temporary password: \"$tpass\", roles: \"$roles\""
}

if [ -n "$INPUT_GROUP" ]; then 
  nopass_users=$(aws iam get-group --group-name $INPUT_GROUP | jq ".Users[] | select(.PasswordLastUsed == null) | .UserName" | tr -d '"')
  target_users=()
  for user in $nopass_users; do
    aws iam get-login-profile --user-name $user >& /dev/null || {
      # add if no login-profile
      target_users+=($user)
    }
  done

  [[ -z ${target_users} ]] && warning_exit "No available users for password creation."

  echo "Detected the following users available for termporary password creation:"
  echo "------------------------"
  for tuser in "${target_users[@]}"; do echo $tuser; done
  echo "------------------------"
  confirm "Do you want to continue?" || warning_exit "Cancelled. No actions applied"

  echo "Setting password..."
  for tuser in "${target_users[@]}"; do
    set_temp_password $tuser
  done
fi

if [ -n "${INPUT_USER}" ]; then
  aws iam get-login-profile --user-name ${INPUT_USER} >& /dev/null && warning_exit "This user already has the login profile. Skipped it."
  confirm "Will create temporary password for user \"${INPUT_USER}\". Do you want to continue?" || warning_exit "Cancelled. No actions applied."
  set_temp_password ${INPUT_USER}
fi

echo
echo "AWS console login: https://${AWS_ACCOUNT_ID}.signin.aws.amazon.com/console"
echo
echo "You can send these credentials to each user via email or chat, they will be forced to choose a new password before being able to use their account."
echo

echo "Setting done"
