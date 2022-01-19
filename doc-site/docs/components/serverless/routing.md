---
title: Routing
sidebar_label: Routing
sidebar_position: 2
---


## Routes
All the routes are configured in AWS API Gateway in backend's [`template.yaml`][template-yaml]

## Domain
The domain is expected to pointed to an AWS hosted-zone same as our EKS setup, in terraform we provision a TLS certificate and store the ARN in SSM for reference in the `template.yaml`. With the Certificate setup AWS SAM will help you modify the Route53 entry to point to API Gateway.

### Authenticator
Endpoints setup for authenticator, these are used to facilitate the login and token exchange flow, and allow web applications to get the authentication status of a client.
- `GET /login`
- `GET /logout`
- `GET /callback`
- `GET /whoami`



### Application
#### Requires Authentication
- `GET /{proxy+}`
- `POST /{proxy+}`
- `PUT /{proxy+}`
- `PATCH /{proxy+}`
- `DELETE /{proxy+}`

:::note 
Wildcard HTTP Method is not used because if `OPTIONS` are routed to the application it will need to specifically handle this case
:::
#### No Authentication
- `GET /status`



[template-yaml]: https://github.com/commitdev/zero-backend-node/blob/577af42c78f936b9e6d8cd09eac0f57a610b5cd2/templates/template.yaml
