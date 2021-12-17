locals {
  # user-auth:enabled will allow deployer to manage oathkeeper rules, otherwise concats with []
  auth_enabled = <% if eq (index .Params `userAuth`) "yes" %>true<% else %>false<% end %>
  auth_deploy_rules = local.auth_enabled ? [{
      verbs      = ["get", "create", "delete", "patch", "update"]
      api_groups = ["*"]
      resources  = ["rules"]
    }] : []

  # define Kubernetes policy for developer
  k8s_developer_access = [
    {
      verbs      = ["exec", "list"]
      api_groups = [""]
      resources  = ["pods", "pods/exec", "pods/portforward"]
      }, {
      verbs      = ["get", "list", "watch"]
      api_groups = ["*"]
      resources = ["deployments", "configmaps", "pods", "pods/log", "pods/status", "nodes", "jobs", "cronjobs", "services", "replicasets",
        "daemonsets", "endpoints", "namespaces", "events", "ingresses", "statefulsets", "horizontalpodautoscalers", "horizontalpodautoscalers/status", "replicationcontrollers"
      ]
    }
  ]

  # define Kubernetes policy for operator
  k8s_operator_access = [
    {
      verbs      = ["exec", "create", "list", "get", "delete", "patch", "update", "watch"]
      api_groups = ["*"]
      resources = ["deployments", "configmaps", "pods", "pods/exec", "pods/log", "pods/status", "pods/portforward",
        "nodes", "jobs", "cronjobs", "statefulsets", "secrets", "externalsecrets", "services", "daemonsets", "endpoints", "namespaces", "events", "ingresses",
        "horizontalpodautoscalers", "horizontalpodautoscalers/status",
        "poddisruptionbudgets", "replicasets", "replicationcontrollers"
      ]
    }
  ]

  # define Kubernetes policy for deployer
  k8s_deployer_access = concat([
    {
      verbs      = ["create", "list", "get", "delete", "patch", "update", "watch"]
      api_groups = ["*"]
      resources = ["deployments", "configmaps", "pods", "pods/log", "pods/status",
        "jobs", "cronjobs", "services", "daemonsets", "endpoints", "namespaces", "events", "ingresses",
        "horizontalpodautoscalers", "horizontalpodautoscalers/status",
        "poddisruptionbudgets", "replicasets", "externalsecrets"
      ]
    },
    {
      verbs      = ["create", "delete", "patch", "update"]
      api_groups = ["*"]
      resources  = ["secrets"]
    }
  ], local.auth_deploy_rules)
}
