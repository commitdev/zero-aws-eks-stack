---
title: Authentication
sidebar_label: Authentication
sidebar_position: 3
---

Authentication is invoked through the API gateway, this allows the decoupling of Authentication from the business logic, and also allows reusing this authentication logic for other endpoints.

Our implementation uses the [Lambda-authorizer flow][lambda-authorizer-flow] documented in AWS, this gives more flexibility of the behavior than the JWT authorizer flow which perform similar functionality. Such as implementing login/logout/callback endpoints, configuring HTTPs cookie and etc.

## OIDC Authorizer
Supports OpenID Connect compliant solutions with Oauth2 based authentication flow

| Environment Variables  | Description | Defaults |
|------------------------|-------------|----------|
| NODE_ENV               | When set as `development` the authenticator listens on a PORT instead of exporting as lambda function  | - |
| ISSUER_BASE_URL        | Issuer with OpenID Connect configured, should have a `.well-known/openid-configuration` setup | - |
| CLIENT_ID              | Client ID for issuer to exchange for tokens | - |
| CLIENT_SECRET          | Client Secret for issuer to exchange for tokens | - |
| COOKIE_DOMAIN          | Scoping Cookies to be only readable in configured domains | - |
| COOKIE_SIGNING_SECRET  | Secret used to encrypt the cookie secret | - |
| AUTH_ENDPOINT          | Authentication service callbacks to exchange and set token | - |
| FRONTEND_URL           | Frontend for CORS and redirection to web application | - |
| AUTH_SCOPE             | scope of authentication | `openid profile email` |
| ALLOW_INSECURE_COOKIES | Allow insecure cookie to be set on client, this should only be allowed in testing environments | `false` |
| JWT_COOKIE_KEY         | By default authenticator will sign a JWE, specify this key to set a JWT in the cookie | - |

## Auth Middleware
Authenticator is invoked by API Gateway and the context is passed down via `requestContext.authorizer.lambda`, all the JWT claims will also be available in this context, to change or modify the context you can update the authorizer lambda function.


[lambda-authorizer-flow]: https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html#api-gateway-lambda-authorizer-flow 