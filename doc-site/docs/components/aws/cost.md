---
title: Understanding the infrastructure cost
sidebar_label: AWS Infrastructure Cost
sidebar_position: 1
---

:::note TODO
To have a better breakdown / updated version
:::

## How much does this stack cost?
The expected total monthly cost: $ 0.202 USD / hr or ~$150USD / month. The most expensive component will be the EKS cluster as well as the instances that it spins up. Costs will vary depending on the region selected but based on us-west-2 the following items will contribute to the most of the cost of the infrastructure:

EKS Cluster: $0.1 USD / hr
NAT Gateway: $0.045 USD / hr
RDS (db.t3.small): $0.034 USD / hr
EC2 (t2.small): $0.023 USD / hr
EC2 instance sizing can be configured in terraform/environments/stage/main.tf
