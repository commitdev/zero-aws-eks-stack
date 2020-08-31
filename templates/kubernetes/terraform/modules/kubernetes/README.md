# kubernetes tf module

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

[Metrics Server](https://github.com/kubernetes-sigs/metrics-server)
A collector of cluster-wide resource metrics.
Used by things like HorizontalPodAutoscaler to determine the current usage of pods. Also allows the `kubectl top` command

[Kubernetes Dashboard](https://github.com/kubernetes/dashboard)
A web-based GUI for viewing and modifying resources in a Kubernetes cluster. Usage instructions below.


## IRSA Support for POD level of access

```
An official method [IRSA (IAM Roles for Service Accounts)](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/) is introduced. This uses their OIDC IAM support to be able to mount tokens into pods automatically that can then be used to auth with the AWS API using a specific role. Any pods that come up in that deployment will automatically have env vars injected called `AWS_ROLE_ARN` and `AWS_WEB_IDENTITY_TOKEN_FILE` that will let them use the AWS API.

Module `irsa` is created to allow a pod to have a specific level of access. You need to:

- Modify policy-application under environments/<env>/application_iam_policy.tf and corresponding main.tf with variables passing to module irsa
- Use created service account in your deployment spec
```


## Organization

```
    main.tf - Configuration entrypoint.
    external_dns.tf - Set up external-dns
    ingress/ - Provision nginx-ingress-controller.
    monitoring/ - Provision cluster monitoring (cloudwatch agent and fluentd).
```


## Dashboard

Kubernetes dashboard will be installed and can be reached by running the following:
(MacOS specific - requires `kubectl`, `jq`)

```
kubectl get secret -o json -n kubernetes-dashboard $(kubectl get secret -n kubernetes-dashboard | grep dashboard-user-token | awk '{print $1}') | jq -r .data.token | base64 -D | pbcopy && \
open "http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login" && kubectl proxy
```

This will get the token from k8s secrets, copy it to your clipboard, open a browser to the dashboard, and forward the appropriate port.

