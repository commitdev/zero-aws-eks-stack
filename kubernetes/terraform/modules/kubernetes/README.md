# kubernetes tf module

## Introduction

This Terraform module contains configuration to provision kubernetes resources.

## Core Components

[Nginx Ingress Controller](https://github.com/kubernetes/ingress-nginx/)
Use Nginx as a reverse proxy and load balancer for your cluster. This will create an AWS load balancer (ELB/ALB/NLB) and whenever an ingress is created to route traffic to your application, the controller will make sure the LB is up to date and sending traffic where it needs to go.

[External DNS](https://github.com/kubernetes-sigs/external-dns)
For any ingresses that are added to route traffic for hosts, external-dns will automatically create DNS records for those hosts and point it to the LB created by the ingress controller.
This makes is extremely easy to bring up a new site at a specific domain or subdomain.

[Cert Manager](https://github.com/jetstack/cert-manager)
For any ingresses that specify that they need TLS, cert-manager will automatically provision a certificate using Lets Encrypt, and handle renewing it automatically on a regular basis.
Alongside external-dns, this allows you to make sure your new domains are always secured using HTTPS.

[Cloudwatch Agent/Fluentd](https://github.com/fluent/fluentd)
A unified logging layer, Fluentd handles capturing all log output from your cluster and routing it to various sources like Cloudwatch, Elasticsearch, etc.


...

## Organization

```
    main.tf - Configuration entrypoint.
    external_dns.tf - Set up external-dns
    ingress/ - Provision nginx-ingress-controller.
    monitoring/ - Provision cluster monitoring (cloudwatch agent and fluentd).
```
