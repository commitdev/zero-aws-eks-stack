---
apiVersion: v1
kind: Secret
metadata:
  name: $PROJECT_NAME
  namespace: $NAMESPACE
type: Opaque
stringData:
  DATABASE_USERNAME: $DB_APP_USERNAME
  DATABASE_PASSWORD: $DB_APP_PASSWORD
