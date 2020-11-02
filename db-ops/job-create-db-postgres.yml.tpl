apiVersion: v1
kind: Namespace
metadata:
  name: db-ops
---
apiVersion: v1
kind: Secret
metadata:
  name: db-create-users
  namespace: db-ops
type: Opaque
stringData: 
  create-user.sql: |
    DROP USER $DB_APP_USERNAME;
    CREATE USER $DB_APP_USERNAME WITH ENCRYPTED PASSWORD '$DB_APP_PASSWORD';
    GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_APP_USERNAME;
  RDS_MASTER_PASSWORD: $MASTER_RDS_PASSWORD
---
apiVersion: v1
kind: Namespace
metadata:
  name: $PROJECT_NAME
---
apiVersion: v1
kind: Secret
metadata:
  name: $PROJECT_NAME
  namespace: $PROJECT_NAME
type: Opaque
stringData: 
  DATABASE_USERNAME: $DB_APP_USERNAME
  DATABASE_PASSWORD: $DB_APP_PASSWORD
---
apiVersion: batch/v1
kind: Job
metadata:
  name: db-create-users-$JOB_ID
  namespace: db-ops
spec:
  template:
    spec:
      containers:
      - name: create-rds-user
        image: $DOCKER_IMAGE_TAG
        command: 
        - sh
        args: 
        - '-c' 
        - psql -U$MASTER_RDS_USERNAME -h $DB_ENDPOINT $DB_NAME -a -f/db-ops/create-user.sql > /dev/null
        env:
        - name: PGPASSWORD
          valueFrom:
            secretKeyRef:
              name: db-create-users
              key: RDS_MASTER_PASSWORD
        volumeMounts:
        - mountPath: /db-ops/create-user.sql
          name: db-create-users
          subPath: create-user.sql
      volumes:
        - name: db-create-users
          secret:
            secretName: db-create-users
      restartPolicy: Never
  backoffLimit: 1
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
