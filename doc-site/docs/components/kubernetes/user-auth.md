---
title: User authentication
sidebar_label: User Authentication
sidebar_position: 1
---

## Overview
Zero stack ships with an Identity & Access proxy and a User management system using ORY's [Oathkeeper] and [Kratos], out of the box it will provide you a suite of features from Register & Login & Session management & Authentication, providing you a secure way of managing users and requests.

## Features
The modules in combination with frontend, backend and infrastructure module offers a end-to-end example so Users can Register then sign-in from the frontend, make authenticated only requests to backend a retrieve data deployed on your cluster.

### Kratos
- Register / Login / Resset password flow
- Csrf tokens / enforcement for forms
### Oathkeeper
- Authentication proxy (setups to use https cookie)
- Session management and request headers management
- JWT tokens signing / verification

## Authentication
The default setup uses an Authenticator handler: [`cookie_session`][oathkeeper-cookie-session] to query Kratos(User-identity Management) to validate sessions, then uses Mutator handler [`id_token`][oathkeeper-id-token] to sign JWT tokens(OpenID Connect ID Token) for the sessions.

## Authorization
  In our example we only include authentication example but not authorization, Oathkeeper supports a suite of handlers including Authorizer, see documentation on how to use Oathkeeper to Authorize requests https://www.ory.sh/oathkeeper/docs/pipeline/authz

## Functional components
- Kratos
  - Kratos controller
  - User identity database
  - Social Sign-ins

- Oathkeeper
  - Oathkeeper proxy
  - Oathkeepr rules Maester

### Deployment components
- Ingress (replacing the normal application ingress)
- Kratos
- User-identity database
- Kubernetes secret
  - credentials for Kratos to connect to Database
- Oathkeeper
- Oathkeeper-measter
- Oathkeeper rules
- jwks_private_key (Oathkeeper uses this key to sign session tokens)

## Configuring
The default values can be overriden using the variable `kratos_values_override` and `oathkeeper_values_override`. You can pass in an object that is a subset of the Kratos or Oathkeeper config in the same nesting level and it will merge with the default values.

### Overriding Kratos config
For example if you want to change the Kratos error UI page you can override it as follows:
```hcl
kratos_values_override = {
  kratos = {
    config = {
      selfservice = {
        flows = {
          error = {
            ui_url = "https://<my-site.com>/custom-error-page"
          }
        }
      }
    }
  }
}
```

#### Config references
View the possible configurations for:
- [Kratos Configuration Reference](https://www.ory.sh/kratos/docs/v0.5/reference/configuration)
- [Oathkeeper Configuration Reference](https://www.ory.sh/oathkeeper/docs/reference/configuration)

These config get mounted during deployment under `/etc/config` in the deployment from [Helm Charts][kratos-helm-deployment]

### Oathkeeper Proxy Rules
Oathkeeper rules are how you control auth decision making and routing through the proxy. Requests coming into the proxy only do something if they match a rule.
Each rule must have a **unique pattern matching string** (glob/regexp) and you can define which [handlers it must go through](https://www.ory.sh/oathkeeper/docs/pipeline) (Authenticators, Authorizers, Mutators, Error handlers), then at the end it can have an upstream service which is the destination of the requests (most likely your service).

:::caution
Incoming must match exactly 1 rule or Oathkeeper will throw an error.
:::

#### Zero's Proxy Rules setup
In our default setup there are 4 rules

| Name/Upstream | Routes | Purpose |
| ---- | ----- | ------- |
| Public Kratos | `/.ory/kratos/public` | Self serve auth flows to facilitate forms and redirects |
| Admin Kratos | `/.ory/kratos/` | Handling request life cycle, only allows GET from external, other calls can be made internally in your cluster |
| Backend public | `<(public\|webhook)\/.*>` | Public endpoints with no auth requirements |
| Authenticated public | `<(?!(public\|webhook\|\.ory\/kratos)).*>` | Authenticated endpoints |

### Documentation
- [Terraform implementation and Documentation][commit-zero-aws/user-auth]
- [ORY Kratos's][kratos-docs] and [Oathkeeper's][oathkeeper-docs] documentation.

[kratos-docs]: https://www.ory.sh/kratos/docs/
[kratos-helm-deployment]: https://github.com/ory/k8s/blob/8b102605a03ba638192778f1de7dfe5e8dd651e8/helm/charts/kratos/templates/deployment.yaml#L106
[oathkeeper-docs]: https://www.ory.sh/kratos/docs/
[kratos]: https://github.com/ory/kratos
[oathkeeper]: https://github.com/ory/oathkeeper
[oathkeeper-cookie-session]: https://www.ory.sh/oathkeeper/docs/pipeline/authn#cookie_session
[oathkeeper-id-token]: https://www.ory.sh/oathkeeper/docs/pipeline/mutator#id_token
[commit-zero-aws/user-auth]: https://registry.terraform.io/modules/commitdev/zero/aws/latest/submodules/user_auth