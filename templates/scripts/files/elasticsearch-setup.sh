#!/bin/sh
set -e
# This file will be pushed into a configmap and executed inside a container in the kubernetes cluster.
# This will allow it to access Elasticsearch

echo "Executing Elasticsearch queries to configure the ${ENVIRONMENT} environment"

# Create the index pattern
curl -X POST "https://${ES_ENDPOINT}/_plugin/kibana/api/saved_objects/index-pattern" -H 'kbn-xsrf: true' -H 'Content-Type: application/json' \
    -d'{"attributes":{"title":"fluentd-*","timeFieldName":"@timestamp","fields":"[]"}}'

if [ "${ENVIRONMENT}" = "stage" ]; then
    # Create the policy
    curl -X PUT "https://${ES_ENDPOINT}/_opendistro/_ism/policies/hot_cold_delete_workflow?pretty" -H 'Content-Type: application/json' -d@/elasticsearch-index-policy-stage.json
    # Make indices use the policy
    curl -X PUT "https://${ES_ENDPOINT}/_template/fluentd_template?pretty" -H 'Content-Type: application/json' \
    -d'{ "index_patterns": ["fluentd-*"], "settings": { "number_of_shards": 2, "number_of_replicas": 1, "opendistro.index_state_management.policy_id": "hot_cold_delete_workflow" }}'
else
    # Create the policy
    curl -X PUT "https://${ES_ENDPOINT}/_opendistro/_ism/policies/hot_warm_cold_delete_workflow?pretty" -H 'Content-Type: application/json' -d@/elasticsearch-index-policy-prod.json
    # Make indices use the policy
    curl -X PUT "https://${ES_ENDPOINT}/_template/fluentd_template?pretty" -H 'Content-Type: application/json' \
    -d'{ "index_patterns": ["fluentd-*"], "settings": { "number_of_shards": 2, "number_of_replicas": 2, "opendistro.index_state_management.policy_id": "hot_warm_cold_delete_workflow" }}'
fi
