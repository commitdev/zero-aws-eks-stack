# infrastructure
Terraform infrastructure as code

## Dependencies
The only things that will need to be set up before deploying for the first time are an AWS account, and a domain name with a Route53 zone created for it.
You'll also need a user created and the credentials available in your shell.

[AWS Docs: Set up the AWS CLI](https://docs.aws.amazon.com/polly/latest/dg/setup-aws-cli.html)
[AWS Docs: Register a domain with Route53](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-register.html)

## Instructions
To init and apply the terraform configs, simply run the makefile and specify the environment. The default environment is `staging`
```
make ENV=<environment>
```

## AWS Stack
All the modules that are being applied can be found in [terraform/modules/environment/main.tf](terraform/modules/environment/main.tf)
- [ ] VPC - [Virtual Private Cloud](https://aws.amazon.com/vpc/pricing/)
- [ ] EKS - [Elastic Kubernetes Service](https://aws.amazon.com/eks/pricing/)
- [ ] EC2 - [Elastic Comput Cloud orchestrated by EKS](https://aws.amazon.com/eks/pricing/)
- [ ] S3 - [Simple Storage Service](https://aws.amazon.com/s3/pricing/)
- [ ] Cloudfront - [Cloudfront Pricing](https://aws.amazon.com/cloudfront/pricing/)
- [ ] ECR - [Elastic Container Registry](https://aws.amazon.com/ecr/pricing/)

## Costs
The most expensive component will be the EKS cluster as well as the instances that it spins up. The rest of the modules have very low cost
- Costs will vary depending on the region selected but based on `us-west-2` the following items will contribute to the most of the cost of the infrastructure
- EKS Cluster: $0.1 USD / hr
- NAT Gateway: $0.045 USD / hr
- RDS (db.t3.small): $0.034 USD / hr
- EC2 (t2.small): $0.023 USD / hr
- Expected total monthly cost: $ 0.202 USD / hr or ~$150USD / month

EC2 instance sizing can be configured in [terraform/environments/staging/main.tf](terraform/environments/staging/main.tf)


## AWS Setting the Kubernetes context
```
aws eks update-kubeconfig --name <cluster-name> --region us-west-2
aws eks update-kubeconfig --name <cluster-name> --region us-west-2 --role-arn <role-arn>
```

## Workin with Kubernetes
Running Bash
```
kubectl run -it --image ubuntu bash
```

Getting secrets
```
kubectl get secret --namespace default <secret-key> -o jsonpath="{.data.password}" | base64 --decode; echo
```
Port forward
```
kubectl port-forward --namespace default $(kubectl get pods --namespace default -l app.kubernetes.io/instance=keycloak -o jsonpath="{.items[0].metadata.name}") 8080
```

## AWS ECR Container Image Hosting

### 1. Creating an ECR repository
```
aws ecr describe-repositories --region us-west-2
aws ecr create-repository --repository-name <ecr-repo-name> --region <aws-region>
aws ecr delete-repository --repository-name <ecr-repo-name> --region <aws-region>
```
Describing the ECR repositories will also give you a list of the fully resolved repository URI.

If you need your AWS account ID, you can use:
```
aws sts get-caller-identity --query Account --output text
```

### 2. Authenticate your Docker with AWS ECR
[AWS DOCS: Registry Authentication](https://docs.aws.amazon.com/AmazonECR/latest/userguide/Registries.html#registry_auth)
```
aws ecr get-login --region <region> --no-include-email
```
This will output a docker command for you to login with the password. Eg. `docker login -u AWS -p password https://<aws_account_id>.dkr.ecr.<region>.amazonaws.com`

### 3. Push your Docker image to the repository
[AWS Docs: Docker Push ECR Image](https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html)

Make sure you have a docker image withe the appropriately named tag that corresponds to an ECR repo.
```
docker build --tag <aws_account_id>.dkr.ecr.<region>.amazonaws.com/<ecr-repo-name> .
```
or for an existing image
```
docker tag <dockerImage> <aws_account_id>.dkr.ecr.<region>.amazonaws.com/<ecr-repo-name>
```
then just docker push
```
docker push <aws_account_id>.dkr.ecr.<region>.amazonaws.com/<ecr-repo-name>
```

### Getting Secrets from AWS Secrets Manager
The terraform by default generates random password during for the RDS instance and stores it in AWS secrets manager
[Using AWS Secretsmanager](https://github.com/aws-samples/aws-workshop-for-kubernetes/tree/master/04-path-security-and-networking/401-configmaps-and-secrets#secrets-using-aws-secrets-manager)
```
aws secretsmanager list-secrets
aws secretsmanager get-secret-value --secret-id <SECRETNAME> --region <REGION>
```

## Setting up RDS

In a Kubernetes cluster you'll need to run bash container to access the RDS in VPC
```
kubectl run -it --image ubuntu bash
kubectl exec -it <bash-pod-id> -- /bin/bash
```

In the container shell
```
Apt-get update -y
Apt-get install pgcli
pgcli -h <rds-url> -U master_user -d postgres
CREATE DATABASE <database>;
create USER <db-user> with password '<db-password>';
GRANT ALL PRIVILEGES ON DATABASE <database> to <db-user>;
```

### Accessing Database in VPC:
```
kubectl run --restart=Never --image=alpine/socat db-gateway -- -d -d tcp-listen:5432,fork,reuseaddr tcp-connect:<RDS_ADDRESS>:5432
kubectl port-forward db-gateway 5432:5432
```
