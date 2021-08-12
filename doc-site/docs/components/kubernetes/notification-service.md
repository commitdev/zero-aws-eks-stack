---
title: Notification service
sidebar_label: Notification service
sidebar_position: 5
---

## Overview
[Zero notification service][zero-notification-service] is a helm-chart ready service to let you send transactional notifications to multiple platforms via API:
- email
  - sendgrid
- push notification
  - slack
- SMS capabilities
  - twillio

## REST API
The API is defined using OpenAPI 3.0 and you explore the service details using
- view the [API specs yaml file][notification-api-specs] or
- with any compatible tools such as [Swagger Editor][browse-api-spec]

## Configuring
By default Zero uses helm to bundle the service, you just need to enable the service and provide necessary API keys and it will work out of the box.
### Available values
[See helm chart][notification-available-values] for all the available values, under `application` you can set up your API keys and application related parameters.
### Setting up API keys
API keys will be created as a Kubernetes secret. It is recommended you use `set_sensitive` in terraform similar to [this example][eks-set-sensitive-example]


[See Documentation][notification-service-config] on how to configure service with environment variables

[zero-notification-service]: https://github.com/commitdev/zero-notification-service
[notification-service-config]: https://github.com/commitdev/zero-notification-service/#configuration
[notification-api-specs]: https://github.com/commitdev/zero-notification-service/blob/main/api/notification-service.yaml
[notification-available-values]: https://github.com/commitdev/zero-notification-service/blob/main/charts/zero-notifcation-service/values.yaml
[eks-set-sensitive-example]: https://github.com/commitdev/zero-aws-eks-stack/blob/2c9344429ef52dab355c8d7e66b9c3571845c7e0/templates/kubernetes/terraform/modules/kubernetes/notification_service.tf#L66-L74
[browse-api-spec]: https://editor.swagger.io/?url=https%3A%2F%2Fraw.githubusercontent.com%2Fcommitdev%2Fzero-notification-service%2Fmain%2Fapi%2Fnotification-service.yaml