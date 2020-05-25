# Infrastructure

**Prerequisites**
 - Terraform installed
 - Kubectl installed
 - Wget installed
 - A valid AWS account
 - [Set up the AWS CLI](https://docs.aws.amazon.com/polly/latest/dg/setup-aws-cli.html)
 - [A domain registered with Route53](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-register.html)
   - Note: if you want to use different domain per environment (staging/poduction), you need to have multiple hosted zones. The available zones in Route53 can be found by running this command. `aws route53 list-hosted-zones`

### Using the Kubernetes Cluster

Before using the cluster the first time you'll need to set up your local `kubectl` context:
```shell
make update-k8s-conf
```

Then you should be able to run commands normally:
```shell
kubectl get pods -A
```


### Apply Configuration
To init and apply the terraform configs, simply run the `make` and specify the
environment. The default environment is `staging`
```shell
$ make ENV=<environment>
```


### Set up an application
Configure your k8s context

```shell
$ aws eks update-kubeconfig --name <cluster-name> --region us-east-1
```
