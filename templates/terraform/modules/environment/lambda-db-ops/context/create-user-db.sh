#!/bin/bash

## Invoke and capture REQUEST ID
INVOKE_URL="http://$AWS_LAMBDA_RUNTIME_API/2018-06-01/runtime/invocation/next"
# OUTPUT=$(curl -is http://$AWS_LAMBDA_RUNTIME_API/2018-06-01/runtime/invocation/next)

INVOKE_RESPONSE=$(curl -si -w "\n%{size_header},%{size_download}" "${INVOKE_URL}")

# Extract the response header/body size.
headerSize=$(sed -n '$ s/^\([0-9]*\),.*$/\1/ p' <<< "${INVOKE_RESPONSE}")
bodySize=$(sed -n '$ s/^.*,\([0-9]*\)$/\1/ p' <<< "${INVOKE_RESPONSE}")

# Extract the response headers/body
headers="${INVOKE_RESPONSE:0:${headerSize}}"
body="${INVOKE_RESPONSE:${headerSize}:${bodySize}}"

REQUEST_ID=$(echo -n "$headers" | grep --color=never "Lambda-Runtime-Aws-Request-Id" | sed  's/Lambda-Runtime-Aws-Request-Id: //' | awk '{ print $1 }')

echo "Lambda RequestId: $REQUEST_ID"
echo -n "Parsed Keys:"
echo "$body" | jq 'keys'

# Convert body map into Env-var
for s in $(echo "$body" | jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" ); do
  export $s
done

# Parsing lambda json input into boolean values
if [[ "$FORCE_CREATE_USER" == "true" ]]; then
  CHECK_DB_EXIST=false
else
  CHECK_DB_EXIST=true
fi
$CHECK_DB_EXIST && echo "CHECKING DB EXISTENCE" || echo "BYPASSING DB EXISTENCE CHECK"

if [[ "$DB_TYPE" == "postgres" ]]; then
  for db in $DB_NAME_LIST; do
    echo "Initiating Database($db) creation"
    ($CHECK_DB_EXIST && (echo '\l' | PGPASSWORD="$MASTER_RDS_PASSWORD" psql -U$MASTER_RDS_USERNAME -h $DB_ENDPOINT postgres | grep -q $db && echo "Database($db) already exist"))|| \
    eval "echo \"$(cat ./postgres-create-user.sql)\"" | \
    sed "s/{{ VAR_DB }}/$db/g" | \
    PGPASSWORD="$MASTER_RDS_PASSWORD" psql -U$MASTER_RDS_USERNAME -h $DB_ENDPOINT postgres -v ON_ERROR_STOP=1 > /dev/null
  done
elif [[ "$DB_TYPE" == "mysql" ]]; then
  for db in $DB_NAME_LIST; do
    echo "Initiating Database($db) creation"
    ($CHECK_DB_EXIST && ((echo "show databases;" | MYSQL_PWD="$MASTER_RDS_PASSWORD" mysql -u$MASTER_RDS_USERNAME -h $DB_ENDPOINT | grep -q $db && echo "Database($db) already exist")) || \
    eval "echo \"$(cat ./mysql-create-user.sql)\"" | \
    sed "s/{{ VAR_DB }}/$db/g" | \
    MYSQL_PWD="$MASTER_RDS_PASSWORD" mysql -u$MASTER_RDS_USERNAME -h $DB_ENDPOINT
  done
fi

echo "FINISHED EXECUTING QUERY"
## Respond to Lambda upon finish
curl -XPOST "http://$AWS_LAMBDA_RUNTIME_API/2018-06-01/runtime/invocation/$REQUEST_ID/response" -d 'SUCCESS'
echo "Script finished successfully"
