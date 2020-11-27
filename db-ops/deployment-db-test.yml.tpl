apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db-pod
  namespace: $PROJECT_NAME
spec:
# this is purposely left at 0 so it can be enabled for troubleshooting purposes
  replicas: 0
  selector:
    matchLabels:
      app: db-pod
  template:
    metadata:
      labels:
        app: db-pod
    spec:
      automountServiceAccountToken: false
      containers:
      - command:
        - sh
        args:
        - "-c"
        # long running task so the pod doesn't exit with 0
        - tail -f /dev/null
        image: $DOCKER_IMAGE_TAG
        imagePullPolicy: Always
        name: db-pod
        env:
        - name: DB_ENDPOINT
          value: $DB_ENDPOINT
        - name: DB_NAME
          value: $DB_NAME
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: $PROJECT_NAME
              key: DATABASE_USERNAME
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: $PROJECT_NAME
              key: DATABASE_PASSWORD
