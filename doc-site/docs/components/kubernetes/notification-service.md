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
The API is defined using OpenAPI 3.0 and you can explore the service details by
- viewing the [API specs yaml file][notification-api-specs] or
- with compatible tools such as [Swagger Editor][browse-api-spec]

## Configuring
By default, Zero uses Helm to bundle the service, you just need to enable it and provide necessary API keys for any services you want to use for notifications and it will work out of the box.

### Available values
[See the Helm chart][notification-available-values] for all the available configuration options. In the `application` section you can set up your API keys and application-related parameters.

### Setting up API keys
Zero will create a secret in AWS SecretsManager, and external-secret is created to poll the values then mounted as a secret to the deployment using values from `zero-project.yml`.

[See Documentation][notification-service-config] on how to configure service with environment variables

[zero-notification-service]: https://github.com/commitdev/zero-notification-service
[notification-service-config]: https://github.com/commitdev/zero-notification-service/#configuration
[notification-api-specs]: https://github.com/commitdev/zero-notification-service/blob/main/api/notification-service.yaml
[notification-available-values]: https://github.com/commitdev/zero-notification-service/blob/main/charts/zero-notifcation-service/values.yaml
[browse-api-spec]: https://editor.swagger.io/?url=https%3A%2F%2Fraw.githubusercontent.com%2Fcommitdev%2Fzero-notification-service%2Fmain%2Fapi%2Fnotification-service.yaml