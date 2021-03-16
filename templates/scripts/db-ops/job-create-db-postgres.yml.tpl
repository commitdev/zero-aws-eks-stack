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
  RDS_MASTER_PASSWORD: $MASTER_RDS_PASSWORD
  create-user.sql: |
    SELECT 'CREATE DATABASE {{ VAR_DB }}' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '{{ VAR_DB }}');\gexec
    SELECT 'CREATE USER $DB_APP_USERNAME' WHERE NOT EXISTS (SELECT FROM pg_user WHERE usename = '$DB_APP_USERNAME');\gexec
    ALTER USER $DB_APP_USERNAME WITH ENCRYPTED PASSWORD '$DB_APP_PASSWORD';
    GRANT ALL PRIVILEGES ON DATABASE {{ VAR_DB }} TO $DB_APP_USERNAME;

---
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE

---
apiVersion: batch/v1
kind: Job
metadata:
  name: db-create-users-$NAMESPACE-$JOB_ID
  namespace: db-ops
spec:
  template:
    spec:
      containers:
      - name: create-rds-user
        image: $DOCKER_IMAGE_TAG
        command:
        - sh
        - -c
        - |
          for db in $DB_NAME_LIST; do
            [[ echo '\l' | psql -U$MASTER_RDS_USERNAME -h $DB_ENDPOINT postgres | grep \$db ]] || \
            cat /db-ops/create-user.sql | \
            sed \"s/{{ VAR_DB }}/\$db/g\" | \
            psql -U$MASTER_RDS_USERNAME -h $DB_ENDPOINT postgres -v ON_ERROR_STOP=1 > /dev/null
          done
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
