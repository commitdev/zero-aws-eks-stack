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

## Documentation
- [Terraform implementation and Documentation][commit-zero-aws/user-auth]
- [ORY Kratos's][kratos-docs] and [Oathkeeper's][oathkeeper-docs] documentation.

[kratos-docs]: https://www.ory.sh/kratos/docs/
[oathkeeper-docs]: https://www.ory.sh/kratos/docs/
[kratos]: https://github.com/ory/kratos
[oathkeeper]: https://github.com/ory/oathkeeper
[oathkeeper-cookie-session]: https://www.ory.sh/oathkeeper/docs/pipeline/authn#cookie_session
[oathkeeper-id-token]: https://www.ory.sh/oathkeeper/docs/pipeline/mutator#id_token
[commit-zero-aws/user-auth]: https://registry.terraform.io/modules/commitdev/zero/aws/latest/submodules/user_auth