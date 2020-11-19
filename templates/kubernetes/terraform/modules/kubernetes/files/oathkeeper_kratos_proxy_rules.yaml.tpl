## Public Kratos
# pattern: http://<proxy>/.ory/kratos/public
# these are the entrypoint of kratos, it handles initialization of forms
# redirections(configured in user_auth.tf from infrastructure)
apiVersion: oathkeeper.ory.sh/v1alpha1
kind: Rule
metadata:
  name: kratos-public
  namespace: user-auth
spec:
  upstream:
    url: http://kratos-public.user-auth
    stripPath: ${public_selfserve_endpoint}
    preserveHost: true
  match:
    url: http://${backend_service_domain}${public_selfserve_endpoint}/<.*>
    methods:
      - GET
      - POST
      - PUT
      - DELETE
      - PATCH
  authenticators:
    - handler: noop
  authorizer:
    handler: allow
  mutators:
    - handler: noop
---
## Kratos Admin
# pattern: http://<proxy>/.ory/kratos
# Note this only allows :GET requests
# Once self-service flow is initiated, a flow_id is generated
# The endpoint is used to exchange for form format / fields given a flow_id
apiVersion: oathkeeper.ory.sh/v1alpha1
kind: Rule
metadata:
  name: kratos-form-data
  namespace: user-auth
spec:
  upstream:
    url: http://kratos-admin.user-auth
    stripPath: ${admin_selfserve_endpoint}
    preserveHost: true
  match:
    url: http://${backend_service_domain}${admin_selfserve_endpoint}/self-service/<(login|registration|recovery|settings)>/flows<.*>
    methods:
      - GET
  authenticators:
    - handler: noop
  authorizer:
    handler: allow
  mutators:
    - handler: noop
