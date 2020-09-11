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

Sometimes you may have an application running in the Kubernetes cluster that needs to access the AWS API (S3 is a common example.) In this case you want to be able to have fine-grained control over this, to allow an application only the very specific access it needs.

There is an official method for EKS called [IRSA (IAM Roles for Service Accounts)](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/). This uses AWS IAM OIDC support to be able to mount tokens into pods automatically that can then be used to auth with the AWS API using a specific role. Any pods that come up in that deployment will automatically have env vars injected called `AWS_ROLE_ARN` and `AWS_WEB_IDENTITY_TOKEN_FILE` that will let them use the AWS API.

*Note that you may need to use a minimum specific version of the AWS API to take advantage of this automatically. You can see a list of the version numbers in the link above.*

The `irsa` module makes it easy to grant a pod to have a specific level of access. You need to:

- Create a policy in `environments/<env>/application_iam_policy.tf`, there should already be examples there. These will be the AWS policies that grant a specific level of access to AWS resources.
- Add your policy, namespace and service account name to `application_policy_list` in `environments/<env>/application_iam_policy.tf`. This is a mapping of a policy to a specific application that will run in the cluster.

```
{
   service_account = "backendservice" # The name of your app. Unique per namespace
   namespace       = "my-app"         # The namespace your app is in
   policy          = data.aws_iam_policy_document.resource_access_backendservice
 },
```

- This will create a Kubernetes "service account" in your cluster. You would refrence this in your application deployment manifest inside the pod template:
```
  spec:
    serviceAccountName: backendservice
```


## WireGuard VPN support
WireGuard® is an extremely simple yet fast and modern VPN that utilizes state-of-the-art cryptography. This integration can support users to access internal resources securely. 

- Add your client info (name, ip and public key) into "vpn_client_publickeys" list (under infrastructure/kubernetes/terraform/environments/<env>/main.tf).
```
  # Wireguard configuration
  vpn_server_address = "10.10.199.0/24"
  vpn_client_publickeys = [
    # name, IP, public key
    ["Max C", "10.10.199.201/32", "/B3Q/Hlf+ILInjpehTLk9DZGgybdGdbm0SsG87OnWV0="],
    ["Carter L", "10.10.199.202/32", "h2jMuaXNIlx7Z0a3owWFjPsAA8B+ZpQH3FbZK393+08="],
    ["Your Name", "10.10.199.203/32", "yz6gNspLJE/HtftBwcj5x0yK2XG6+/SHIaZ****vFRc="],
  ]
```

To get the client info, with infrastructure/scripts/add-vpn-user.sh, you will get an auto-generated configuration file as well as client info needed as for above. Sample:
```
Configuration generated at /Users/xxx.yyy/.wireguard/project-1/wg-client.conf with:
  - public key : yz6gNspLJE/HtftBwcj5x0yK2XG6+/SHIaZ****vFRc=
  - private key: G8FJTwIaqznXjb6znHkYOtlieRugWEc/LMC****UKXc=
  - client IP  : 10.10.199.203/32

Please ask DevOps to apply VPN server change with the following line appended to var.vpn_client_publickeys list:

    ["Your Name", "10.10.199.203/32", "yz6gNspLJE/HtftBwcj5x0yK2XG6+/SHIaZ****vFRc="]
```

- Setup your client and access to internal server. You may access to the destination, eg, mysql -h 10.10.10.79 -uxxx -p

Note: at the first time of access, it will take a little longer time for establishing the channel. So you may just run a ping first.

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

