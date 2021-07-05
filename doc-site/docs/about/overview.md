---
title: Overview
sidebar_label: Overview
sidebar_position: 1
---

The Zero-awk-eks stack is designed with scalability and maintainability in mind, this repo is a series of templates indented to be filled in with modules parameters, and executed by zero 
This is a [Zero][zero] module which sets up a
hosting environment on AWS running Kubernetes. It will generate terraform output
which describes the environment mapped in this [architecture diagram][arch-diagram]. 

### **Resource List**: 
[Link][resource-list]

### **Prerequisites**
 - Terraform installed
 - Kubectl installed
 - Wget installed
 - A valid AWS account
 - [Set up the AWS CLI][aws-cli]
 - [A domain registered with Route53][aws-route53]
   - Note: if you want to use different domain per environment (staging/production), you need to have multiple hosted zones. The available zones in Route53 can be found by running this command. `aws route53 list-hosted-zones`

_Optional Prerequisites_
- [Sendgrid account][sendgrid] with developer [API key][sendgrid-apikey]: this will enable transactional email sending with simple API calls.


<!-- Links -->
[zero]: https://github.com/commitdev/zero
[arch-diagram]: ./architecture-overview
[resource-list]: ../components/resources
<!-- External Links -->
[aws-cli]: https://docs.aws.amazon.com/polly/latest/dg/setup-aws-cli.html
[aws-route53]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-register.html
[zenhub-board]: https://app.zenhub.com/workspaces/commit-zero-5da8decc7046a60001c6db44/board?filterLogic=any&repos=203630543,247773730,257676371,258369081
[sendgrid]: https://signup.sendgrid.com
[sendgrid-apikey]: https://app.sendgrid.com/settings/api_keys