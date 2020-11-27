---
apiVersion: v1
kind: Secret
metadata:
  name: $PROJECT_NAME
  namespace: $NAMESPACE
type: Opaque
stringData:
  dsn: $DB_TYPE://$DB_APP_USERNAME:$DB_APP_PASSWORD@$DB_ENDPOINT_FOR_DSN/$DB_NAME
  secretsCookie: cookie-secret-$PROJECT_NAME-$SEED
  secretsDefault: default-secret-$PROJECT_NAME-$SEED
  smtpConnectionURI: $SMTP_URI
