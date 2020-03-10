# infrastructure
Terraform infrastructure as code

## Instructions 
1. Setup the basic infrastructure for either staging / production environment
```
cd terraform 
cd environments/staging
terraform init
terraform apply
```

2. Setup the Kubernetes utilities
```
cd kubernetes/terraform 
cd environments/staging
terraform apply
```