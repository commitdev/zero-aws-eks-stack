# infrastructure
Terraform infrastructure as code

## Instructions 
1. Setup the basic infrastructure for either staging / production environment
```
./init.sh <environment>
```
The supported environment values are currently `staging` and `production`

2. Setup the Kubernetes utilities
```
cd kubernetes/terraform/environments/staging
terraform apply
```