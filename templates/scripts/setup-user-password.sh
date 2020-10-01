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

[[ -z "$INPUT_GROUP" ]] && [[ -z "$INPUT_USER" ]] && INPUT_GROUP="console-allowed" # set default group

[[ -n "$INPUT_GROUP" ]] && [[ -n "$INPUT_USER" ]] && warning_exit "Can not input both group and user togeher"

# Collect users in this group without password
function set_temp_password() {
    user=$1
    tpass=$(aws secretsmanager get-random-password --password-length 16 --require-each-included-type --output text)
    aws iam get-login-profile --user-name $user >& /dev/null
    if [ $? -eq 0 ]; then
      aws iam update-login-profile --user-name $user --password "$tpass" --password-reset-required >& /dev/null
    else
      aws iam create-login-profile --user-name $user --password "$tpass" --password-reset-required >& /dev/null
    fi
    roles=$(aws iam list-groups-for-user --user-name $user | jq '.Groups[] | select(.Path == "/users/") | .GroupName' | tr -d "\"" | tr "\n" " ")
    echo "  username:\"$tuser\", temporary password: \"$tpass\", roles: \"$roles\""
}

if [ -n "$INPUT_GROUP" ]; then 
  nopass_users=$(aws iam get-group --group-name $INPUT_GROUP | jq ".Users[] | select(.PasswordLastUsed == null) | .UserName" | tr -d '"')

  [[ -z ${nopass_users} ]] && warning_exit "No avaialbe users"

  echo "Detected the following users under group '$INPUT_GROUP':"
  echo "------------------------"
  echo "$nopass_users"
  echo "------------------------"
  confirm "Will create temporary password for them. Do you want to continue?" || warning_exit "No actions applied"

  echo "Setting password..."
  for tuser in $nopass_users; do
    set_temp_password $tuser
  done
fi

if [ -n "$INPUT_USER" ]; then
  confirm "Will reset user \"$INPUT_USER\" password. Do you want to continue?" || warning_exit "No actions applied"
  set_temp_password $INPUT_USER
fi

AWS_ACCOUNT_ID=<% index .Params `accountId` %>
echo
echo "AWS console login: https://${AWS_ACCOUNT_ID}.signin.aws.amazon.com/console"
echo

echo "Setting done"
