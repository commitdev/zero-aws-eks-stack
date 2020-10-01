#!/bin/bash

#
# This script to help Admin initialize password for new users
#

function usage() {
  echo "  Usage:"
  echo "    $0 -g|--group <group> -u|--user <user> -h"
  exit 1
}

function warning_exit() {
  echo "WARNING: $1" && exit 2
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
    g) group=$OPTARG ;;
    u) user=$OPTARG ;;
  esac
done

[[ -z "$group" ]] && [[ -z "$user" ]] && group="console-allowed" # set default group

[[ -n "$group" ]] && [[ -n "$user" ]] && warning_exit "Can not input both group and user togeher"

# Collect users in this group without password
if [ -n "$group" ]; then 
  nopass_users=$(aws iam get-group --group-name $group | jq ".Users[] | select(.PasswordLastUsed == null) | .UserName" | tr -d '"')

  [[ -z ${nopass_users} ]] && warning_exit "No avaialbe users"

  echo "Detected the following users under group '$group':"
  echo "------------------------"
  echo "$nopass_users"
  echo "------------------------"
  confirm "Will create temporary password for them. Do you want to continue?" || warning_exit "No actions applied"

  echo "Setting password..."
  for user in $nopass_users; do
    tpass=$(aws secretsmanager get-random-password --password-length 16 --require-each-included-type --output text) && \
    aws iam create-login-profile --user-name $user --password "$tpass" --password-reset-required && \
    echo "username:\"$user\", temporary password: \"$tpass\""
  done
fi

if [ -n "$user" ]; then
    tpass=$(aws secretsmanager get-random-password --password-length 16 --require-each-included-type --output text)
    aws iam get-login-profile --user-name $user >& /dev/null
    if [ $? -eq 0 ]; then
      confirm "Will reset user \"$user\" password. Do you want to continue?" || warning_exit "No actions applied"
      aws iam update-login-profile --user-name $user --password "$tpass" --password-reset-required
    else
      confirm "Will initialize user \"$user\" password. Do you want to continue?" || warning_exit "No actions applied"
      aws iam create-login-profile --user-name $user --password "$tpass" --password-reset-required
    fi
    [[ $? -eq 0 ]] && echo "username:\"$user\", temporary password: \"$tpass\""
fi

AWS_ACCOUNT_ID=<% index .Params `accountId` %>
echo "AWS console login: https://${AWS_ACCOUNT_ID}.signin.aws.amazon.com/console"

echo "Setting done"
