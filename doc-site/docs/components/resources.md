---
title: Resources
sidebar_label: Resources
sidebar_position: 1
---

## Zero components

### **s3 bucket: Terraform-state:** 
`<project>-<env>-terraform-state`
Terraform state s3 bucket is used for storing your terraform state in a terraform [remote backend][tf-remote-backend]

### **dynamo db: Terraform statelock**:
Terraform uses [state lock][tf-remote-state] ensures multiple operators can't attempt to make changes to the infrastructure at the same time 

### **IAM user: `<project>-ci-user`**:
This user is given the ECR full-access policy, our intention is you will push your container images to ECR via this IAM, This user also has access to assume the kubernetes-admin role, which will let it operate the Kuberenetes cluster, and has access to the S3 bucket we create for static assets.

### **Secret manager: `ci-user-aws-key`**:
These credentials will be put into a CI system then used during the build and deploy process, most likely as environment variables.

### **VPC:**
Subnet for AWS, all our resources will be locally accessible with each others created in here
by default everything will be under `10.10.xxx.xxx`, [see details][zero-subnet]

### **EKS-cluster**:
Our main kubernetes stack, core of our infrastructure. Our business logic and application will be deployed here, Kubernetes enables ease of scaling / management of all our microservices. 
Kubernetes will be high availability according to your [az settings][zero-az]

### **EKS: k8s-workers:**
K8s-workers are the backbone to your infrastructure and application, all your processing happens here! They leverage kubernetes to distribute the load onto workers and allow your application to scale effortlessly. K8s-workers are EC2 instances under the hood, any deployments and pods will be spun up in these workers. With Auto-scaling group and cluster-autoscaler your application will be future proofed for growth and scaling.

### **EKS: fluentd / amazon-cloudwatch**:
A unified logging layer, Fluentd handles [capturing][k8s-daemonset] all log output from your cluster and routing it to various sources like Cloudwatch, Elasticsearch, etc; In our default setup logs are routed to cloudwatch-agent which saves our logs into [AWS cloudwatch][aws-cloudwatch] for easy governance. 
- fluentd
- cloudwatch-agent
- aws-cloudwatch 

### **EKS: ingress-nginx**:
Use Nginx as a reverse proxy and load balancer for your cluster. This will create an AWS load balancer (ELB/ALB/NLB) and whenever an ingress is created to route traffic to your application, the controller will make sure the LB is up to date and sending traffic where it needs to go. 

### **EKS: External-dns**:
For any ingresses that are added to route traffic for hosts, external-dns will automatically create DNS records for those hosts and point it to the LB created by the ingress controller. This makes is extremely easy to bring up a new site at a specific domain or subdomain. [How it works][external-dns]

### **EKS: Cert-manager**:
For any ingresses that specify that they need TLS, cert-manager will automatically provision a certificate using Lets Encrypt, and handle renewing it automatically on a regular basis. Alongside external-dns, this allows you to make sure your new domains are always secured using HTTPS. 

To enable cert-manager to create certificates for you using [ClusterIssuer with Zero][zero-cluster-issuer], you would annotate your kubernetes ingress as follows:
```yml
## kubernetes ingress annotations
"cert-manager.io/cluster-issuer": clusterissuer-letsencrypt-production
## spec > tls > secret_name
secret_name = "tls-certificate"
```
Cert-manager will then create a certificate resource, and use letsencrypt ACME servers to validate and deploy the certificate. Within a minute or so, you should should be able to see `kubectl get certificates` as `Ready:true`

### **EKS: Kubernetes Dashboard**
A web-based GUI for viewing and modifying resources in a Kubernetes cluster. The dashboard consists of two parts, a persistence layer and data scraper and the UI itself. 
- [dashboard-metrics-scraper][k8s-metrics-scraper]
- [kubernetes-dashboard][k8s-dashboard]

```sh
# you can access the dashboard with the following command
kubectl get secret -o json -n kubernetes-dashboard $(kubectl get secret -n kubernetes-dashboard | grep dashboard-user-token | awk '{print $1}') | jq -r .data.token | base64 -D | pbcopy && \
open "http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login" && kubectl proxy
```

### **EKS: Metrics-server**
[A collector][k8s-sigs-metrics] of cluster-wide resource metrics. Used by things like HorizontalPodAutoscaler to determine the current usage of pods. Also allows the `kubectl top` command

### **EKS: Cluster-autoscaler**
Automatically scales the number of worker nodes in the Kubernetes cluster as utilization changes, interacts with AWS auto scaling groups to scale the cluster. Scales the cluster based on [defined limits][asg-config].

### **RDS**:
AWS Relational database services, we provision a postgres DB for your application that is within your VPC and accessible by your EKS worker nodes. The database is also pre-configured to be monitored with cloudwatch.

### **wildcard_domain / S3 Hosting / Clent assets distributions**:
- Route53 hosted-zone validation
- Certificate in ACM
- Cloudfront distrubution
- S3 Bucket - Client assets

These resources sets up a certificate of your domain and validates it, then creates a S3 bucket and cloudfront for your frontend assets (eg. hosting your SPA)

### **ECR**:
We create a repository in AWS container registry for your application images, intention is your workflow will use a CI-pipeline to test, build, and push application docker images into this repository; then your kubernetes deployment will pull images to run applications from this registry. 




<!-- Links -->
[tf-remote-backend]: https://www.terraform.io/docs/backends/types/remote.html
[tf-remote-state]: https://www.terraform.io/docs/backends/state.html
[zero-subnet]: https://github.com/commitdev/commit0-aws-eks-stack/blob/master/terraform/modules/vpc/main.tf#L8-L10
[zero-az]: https://github.com/commitdev/commit0-aws-eks-stack/blob/master/terraform/modules/vpc/main.tf#L7
[k8s-daemonset]: https://hub.docker.com/r/fluent/fluentd-kubernetes-daemonset
[aws-cloudwatch]: https://us-east-1.console.aws.amazon.com/cloudwatch/home
[external-dns]: https://medium.com/@jpantjsoha/how-to-kubernetes-with-dns-management-for-gitops-31239ea75d8d
[zero-cluster-issuer]: https://github.com/commitdev/commit0-aws-eks-stack/blob/master/kubernetes/terraform/modules/kubernetes/files/cert_manager_issuer.yaml.tpl#L12
[k8s-dashboard]: https://github.com/kubernetes/dashboard
[k8s-metrics-scraper]: https://github.com/kubernetes-sigs/dashboard-metrics-scraper
[k8s-sigs-metrics]: https://github.com/kubernetes-sigs/metrics-server
[helm-autoscaler]: https://github.com/helm/charts/tree/master/stable/cluster-autoscaler
[asg-config]: https://github.com/commitdev/commit0-aws-eks-stack/blob/ecf2eb318ef6b2caf1a3f1d839bb072f9c810a23/terraform/environments/staging/main.tf#L27-L28