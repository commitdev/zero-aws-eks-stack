# Overview
Your infrastructure should be up and running, your terraform repository is the source of truth for your infrastructure, here is [a list of components and resources][zero-resource-list] that comes with the EKS-stack

# Cloudfront signed URLs
If you've answered "yes" to:

> Enable file uploads using S3 and Cloudfront signed URLs? (Will require manual creation of a Cloudfront keypair in AWS)

Then you will need the root AWS account holder to run:

    scripts/import-cf-keypair.sh

This needs to be executed once for the project to setup an AWS secret.
After it has successfully run once, it never needs to run again for this project.

# How to
## Managing your Terraform
#### Why terraform
The repository follows infrastructure as code as a core principle, it allows repeatable and reproducible infrastructures and makes DevOps much more manageable; to learn more about it we suggest reading the [Terraform's workflow guide][tf-workflow].

#### Intended workflows
To make changes to the infrastructure you would modify the terraform code changing the components you wish to modify, then plan the changes with `terraform plan` to make sure you are making the desired changes; then apply the changes with `terraform apply` on your staging environment. Once you reach the satisfactory state, you should do the same on production environment and check-in the changes of your infrastructure code, as this repo should be the source of truth of your deployed infrastructure.
Our infrastructure is divided into a few areas.
1. Initial setup
  - [remote state][tf-remote-state]
  - [secrets][tf-secrets]
2. Infrastructure
  - [production][tf-production-env]
  - [staging][tf-staging-env]
3. Kubernetes utilities
  - [production][tf-production-utilities]
  - [staging][tf-staging-utilities]


#### Style guide, resources, and Configuring your infrastructure as code
For more information about the terraform in this repo, please see [Link][zero-tf-guide]


## Using the Kubernetes Cluster

Before using the cluster the first time you'll need to set up your local `kubectl` context:
```shell
$ make update-k8s-conf
...
Updated context <context name> in ~/.kube/config
$ kubectl config set-context <context name>
```

Then you should be able to run commands normally:
```shell
$ kubectl get pods -A
```

[Kubernetes Resources](docs/kubernetes.md)

### Apply Configuration
To init and apply the terraform configs, simply run the `make` and specify the
environment. The default environment is `staging`
```shell
$ make ENVIRONMENT=<environment>
```

#### Extra features built into my kubernetes cluster
Outlines and best practices utilities that comes with your EKS cluster.
Please see [Link][zero-k8s-guide]
- [Logging and Metrics](docs/logging-and-metrics.md)
- Ingress / TLS certificates (auto provisioning)
- AWS IAM integration with Kubernetes RBAC
- VPN using Wireguard
...

#### Sending Email with Sendgrid
Setup: If you initialized your infrastructure with a sendgridApiKey, you should have a verified domain with Sendgrid once your infrastructure is setup. We should have created 3 route53 entries for you, and [verified your domain with sendgrid][sendgrid-domain-verification]

Your sendgrid account should be configured, and you can send a test email as follow:
```sh
$ curl --request POST \
  --url https://api.sendgrid.com/v3/mail/send \
  --header 'authorization: Bearer <SENDGRID-API-KEY>' \
  --header 'content-type: application/json' \
  --data '{
	"from": {"email": "test@mail.<verified-domain>"},
  "personalizations": [{
      "subject": "Hello, World!",
      "to": [{
        "email": "<receipient-email>"
      }],
	}],
  "content": [{"type": "text/plain","value": "Hello, World!"}]
}'
```
For Application use, see [Sendgrid resources][sendgrid-send-mail] on how to setup templates to send dynamic transactional emails. To setup emailing from your application deployment, you should create a kubernetes secret with your Sendgrid API Key(already stored in [AWS secret-manager](./terraform/bootstrap/secrets/main.tf)) in your application's namespace. Then mount the secret as an environment variable in your deployment.


## WireGuard VPN support
WireGuard® is an extremely simple yet fast and modern VPN that utilizes state-of-the-art cryptography. This allows users to access internal resources securely.

A WireGuard pod will be started inside the cluster and users can be added to it by appending lines to `kubernetes/terraform/environments/<env>/main.tf`:
```
  vpn_client_publickeys = [
    # name, IP, public key
    ["Your Name", "10.10.199.203/32", "yz6gNspLJE/HtftBwcj5x0yK2XG6+/SHIaZ****vFRc="],
  ]
```

A new user can add themselves to the VPN server easily. Any user with access to the kubernetes cluster should be able to run the script `scripts/add-vpn-user.sh`
This will ask for their name, and automatically generate a line like the one above, which they can then add to the terraform and apply themselves, or give the line to an administrator and ask them to apply it.
The environment they are added to will be decided by the current `kubectl` context. You can see your current context with `kubectl config current-context`.
A user will need to repeat this for each environment they need access to (for example, staging and production.)

*Note that this will try to detect the next available IP address for the user but you should still take care to ensure there are no duplicate IPs in the list.*

It will also generate a WireGuard client config file on their local machine which will be properly populated with all the values to allow them to connect to the server.

The WireGuard client can be downloaded at [https://www.wireguard.com/install/](https://www.wireguard.com/install/)

Once connected to the VPN, the user should have direct access to anything running inside the AWS VPC. AWS resources can be referred to by their internal DNS names, and even things inside the kubernetes cluster may be reached direcly using their `.svc.cluster.local` names.


#### Application database user creation
A database user will automatically be created for a backend application with a random password, and the credentials will be stored in a kubernetes secret in the application namespace so they are available to the application.

_Note: the user creation only happens once during `zero apply`. The creation happens in the script `zero-aws-eks-stack/dp-ops/create-db-user.sh`. This script should most likely not be run again as it could remove any subsequent changes to the db user or kubernetes secret._

#### User management / authentication
If you initialized your infrastructure with the userAuth parameter, Ory [Kratos][kratos] and [Oathkeeper][oathkeeper] will be configured in the Kubernetes cluster.

Kratos is an OIDC-compliant user management tool, it manages the users in your system, including signup, login, password reset, Single Sign-On, etc.
Oathkeeper is a zero-trust Identity & Access Proxy which sits in front of your application and handles authentication, passing traffic on to your backend only when a user is logged in, or in cases where you want to expose something publicly.

All these components should be working out of the box and you can style a front-end for Kratos however you like.
To enable SSO support for Kratos (to log in with Github, Google, etc.) you will need to set up the OIDC providers you want to support. See [the Kratos documentation][kratos-oidc] for a guide.

To specify your provider config you need to create a secret containing your provider configuration in JSON format like so:
```sh
kubectl create secret generic oidc-providers -n user-auth  --from-literal=SELFSERVICE_METHODS_OIDC='{"enabled":true,"config":{"providers":[{"id":"github","provider":"github","client_id":"<id>","client_secret":"<secret>","mapper_url":"http://your-url/github.data-mapper.jsonnet","scope":["user:email"]}]}}'
```

This also requires specifying a mapper file which maps claims from the provider to fields which will be exposed to your app. This must be provided in the `mapper_url` field in the config above. It can be provided as a HTTP URL, a file, or a base64 encoded string.
Here is a simple example for GitHub:
```js
local claims = std.extVar('claims');

{
  identity: {
    traits: {
      email: claims.email, // If email is not set the Jsonnet snippet will fail with an error.
      [if "website" in claims then "website" else null]: claims.website, // The website claim is optional.
    },
  },
}
```

Next, edit `kubernetes/terraform/modules/kubernetes/files/kratos-values.yml` and set `deployment.environmentSecretsName` to the name of the secret you created above.
After restarting kratos, you should see a button appear on the login / signup pages to use the providers you set up.

_Note: Oathkeeper requires a `JWKS` file which should have been created automatically during project setup and saved into a secret in AWS secret manager._

# Resources
###  Infrastructure
This [architecture-diagram][architecture-diagram] displays the original setup you get from the terraform templates

Commonly used links in AWS console
|Resources  |Links|
|---        |---|
|Route 53   |https://console.aws.amazon.com/route53/home |
|IAM        |https://console.aws.amazon.com/iam/home#/users|
|ECR        |https://console.aws.amazon.com/ecr/repositories|
|RDS        |https://console.aws.amazon.com/rds|

### Teardown
Tearing down the infrastructure requires multiple steps, as some of the resources have protection mechanism so they're not accidentally deleted

_Note: the following steps are not reversible, tearing down the cluster results in lost data/resources._
<details>
  <summary>Teardown steps</summary>

```
export ENVIRONMENT=stage/prod
```
1. Navigate to your infrastructure repository (where this readme/makefile provided is located), we will remove the resources in a Last in First out order.
```
make teardown-k8s-utils
```

2. Disable the RDS delete protection of the database https://console.aws.amazon.com/rds. Goal is to delete the entire database, so make sure you **backup your database before going so**.

3. Empty the s3 bucket for your frontend assets, http://s3.console.aws.amazon.com/s3/home

4. teardown the EKS cluster and VPC with the following command:
```
make teardown-env
```
5. teardown the secrets created for CI and RDS with the following command:
```
make teardown-secrets
```
6. Empty the s3 bucket for your terraform backend, http://s3.console.aws.amazon.com/s3/home
    - \<name\>-shared-terraform-state
    - \<name\>-\<environment\>-terraform-state
7. teardown the dynamodb and terraform backend with the following command:
```
make teardown-remote-state
```
</details>

### Suggested readings
- [Terraform workflow][tf-workflow]
- [Why do I want infrastructure as code?][why-infra-as-code]



<!-- Links -->
[tf-workflow]: https://www.terraform.io/guides/core-workflow.html
[why-infra-as-code]: https://www.oreilly.com/library/view/terraform-up-and/9781491977071/ch01.html
[kratos]: https://www.ory.sh/kratos/
[oathkeeper]: https://www.ory.sh/oathkeeper/
[kratos-oidc]: https://www.ory.sh/kratos/docs/guides/sign-in-with-github-google-facebook-linkedin

<!-- code -->
[tf-remote-state]: ./terraform/bootstrap/remote-state
[tf-secrets]: ./terraform/bootstrap/secrets
[tf-production-env]: ./terraform/environments/production
[tf-staging-env]: ./terraform/environments/staging

[tf-production-utilities]: ./kubernetes/terraform/environments/production
[tf-staging-utilities]: ./kubernetes/terraform/environments/staging

[zero-tf-guide]: ./terraform/README.md
[zero-k8s-guide]: ./kubernetes/terraform/modules/kubernetes/README.md
[zero-architecture-diagram]: https://github.com/commitdev/zero-aws-eks-stack/blob/master/docs/architecture-overview.svg
[zero-resource-list]: https://github.com/commitdev/zero-aws-eks-stack/blob/master/docs/resources.md

[sendgrid-domain-verification]: https://app.sendgrid.com/settings/sender_auth
[sendgrid-send-mail]: https://sendgrid.api-docs.io/v3.0/mail-send/v3-mail-send
