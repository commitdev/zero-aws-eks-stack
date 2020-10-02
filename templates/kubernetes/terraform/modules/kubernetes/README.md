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

Once connected to the VPN, the user should have direct access to anything running inside the AWS VPC.

## Organization

```
    main.tf - Configuration entrypoint.
    external_dns.tf - Set up external-dns
    ingress/ - Provision nginx-ingress-controller.
    monitoring/ - Provision cluster monitoring (cloudwatch agent and fluentd).
```

## GUI

If you are interested in a GUI option for viewing / interacting with kubernetes, a good option is Lens[Lens](https://k8slens.dev/).
It's free, open source, cross-platform, and has a great selection of features.
