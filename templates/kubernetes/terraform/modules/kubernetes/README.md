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


## AWS IAM / Kubernetes RBAC integration

Sometimes you may have an application running in your cluster that needs to access the AWS API (S3 is a common example.) In this case you want to be able to have fine-grained control over this, to allow an application only the very specific access it needs.

Previously there were tools like `kube2iam` or `kiam` that would enable this functionality, but now there is a new official method that AWS introduced that they call [IRSA (IAM Roles for Service Accounts)](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/)

This uses their OIDC IAM support to be able to mount tokens into pods automatically that can then be used to auth with the AWS API using a specific role.

The `cert_manager.tf` config has a good example of using this in practice. To allow a pod to have a specific level of access you need to:

- Create a role that allows being assumed by a web identity:
```
module "iam_assumable_role_my_role_name" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v2.14.0"
  create_role                   = true
  role_name                     = "my-role-name"
  provider_url                  = replace(data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer, "https://", "")
  role_policy_arns              = [aws_iam_policy.external_dns.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:my-service-account-name"]
}
```
- Create a service account for your kubernetes service to use, with an annotation specifying which IAM role is associated:
```
resource "kubernetes_service_account" "my_service_account" {
  metadata {
    name        = "my-service-account-name"
    namespace   = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam_assumable_role.my_role_name.this_iam_role_arn
    }
  }
}
```
- Use this service account in your deployment spec.

Any pods that come up in that deployment will automatically have env vars injected called `AWS_ROLE_ARN` and `AWS_WEB_IDENTITY_TOKEN_FILE` that will let them use the AWS API.



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

