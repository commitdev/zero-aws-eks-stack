---
title: Managing your secrets with External Secrets
sidebar_label: External Secrets
sidebar_position: 3
---

## Overview
Kubernetes External Secrets allows you to use external secret management systems, like AWS Secrets Manager or HashiCorp Vault, to securely add secrets in Kubernetes.

## How it works
The project extends the Kubernetes API by adding an ExternalSecrets object using Custom Resource Definition and a controller to implement the behavior of the object itself.

An ExternalSecret declares how to fetch the secret data, while the controller converts all ExternalSecrets to Secrets. The conversion is completely transparent to Pods that can access Secrets normally.

## Application
Along with the database credentials, any other secrets that need to be provided to the application can be managed in AWS Secrets Manager.
Secrets have been created for each environment called `<project-name>/kubernetes/<environment>/<project-name>` which contain a list of environment variables that will be synced with the kubernetes secret in your namespace via a tool called [external-secrets](https://github.com/external-secrets/kubernetes-external-secrets)
Any secrets managed by `external-secrets` will be synced to kubernetes every 15 seconds. Keep in mind that any changes must be made in Secrets Manager, as any that are made to the secret on the kubernetes side will be overwritten.
You can see the `external-secrets` configuration in [kubernetes/overlays/staging/external-secret.yml](https://github.com/commitdev/zero-backend-go/blob/main/templates/kubernetes/overlays/staging/external-secret.yml) (this is the one for staging)

To work with the secret in AWS you can use the web interface or the cli tool:
```
 aws secretsmanager get-secret-value --secret=<project-name>/application/stage/<project-name>
```

The intent is that the last part of the secret name is the component of your application this secret is for. For example: if you were adding a new billing service, the secret might be called `<project-name>/application/stage/billing`

## Documentation
Checkout [External secrets's documentation][docs] for more information.

[docs]: https://github.com/external-secrets/kubernetes-external-secrets#how-to-use-it
