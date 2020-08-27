#!/bin/sh
# This file wil run locally. It will run a run a job inside the kubernetes cluster that will set up indices and a lifecycle policy in Elasticsearch

DOCKER_IMAGE_TAG=commitdev/zero-k8s-utilities:0.0.2
ES_ENDPOINT=$(aws es describe-elasticsearch-domain --domain-name bill-aug21-stage-logging --query "DomainStatus.Endpoints.vpc" | jq -r '.')

kubectl create namespace zero-setup 2>/dev/null || echo "Namespace exists"
kubectl create configmap setup-script -n zero-setup --from-file=files/elasticsearch-setup.sh 2>/dev/null || echo "Setup script exists"
kubectl create configmap index-policy -n zero-setup --from-file=files/elasticsearch-index-policy-stage.json --from-file=files/elasticsearch-index-policy-prod.json 2>/dev/null || echo "Index policy exists"

# Create a job
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: elasticsearch-setup
  namespace: zero-setup
spec:
  template:
    spec:
      containers:
      - name: elasticsearch-setup
        image: ${DOCKER_IMAGE_TAG}
        command: ["sh"]
        args: ["/elasticsearch-setup.sh"]
        env:
        - name: ES_ENDPOINT
          value: ${ES_ENDPOINT}
        - name: ENVIRONMENT
          value: ${ENVIRONMENT}
        volumeMounts:
        - mountPath: /elasticsearch-setup.sh
          name: setup-script
          subPath: elasticsearch-setup.sh
        - mountPath: /elasticsearch-index-policy-stage.json
          name: index-policy
          subPath: elasticsearch-index-policy-stage.json
        - mountPath: /elasticsearch-index-policy-prod.json
          name: index-policy
          subPath: elasticsearch-index-policy-prod.json
      volumes:
        - name: setup-script
          configMap:
            name: setup-script
        - name: index-policy
          configMap:
            name: index-policy
      restartPolicy: Never
  backoffLimit: 0
EOF

echo "Setting up Elasticsearch indices for log storage..."

# Delete the zero-setup namespace after the job is complete
kubectl -n zero-setup wait --for=condition=complete --timeout=20s job elasticsearch-setup
if [ $? -eq 0 ]
then
    echo "Done. Writing elasticsearch setup logs to elasticsearch-setup.log"
    kubectl logs --tail=-1 -n zero-setup -l job-name=elasticsearch-setup > ../elasticsearch-setup.log
    kubectl delete namespace zero-setup
else
    echo "Failed to execute elasticsearch setup, please see 'kubectl logs -n zero-setup -l job-name=elasticsearch-setup'"
fi
