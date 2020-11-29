---
apiVersion: v1
kind: Secret
metadata:
  name: $SECRET_NAME
  namespace: $NAMESPACE
type: Opaque
stringData:
  DATABASE_USERNAME: $DB_APP_USERNAME
  DATABASE_PASSWORD: $DB_APP_PASSWORD
