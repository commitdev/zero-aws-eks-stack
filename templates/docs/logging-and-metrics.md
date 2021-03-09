# Logging

## Cloudwatch
More to come...

## Kibana + Elasticsearch
Logs from all the pods in the cluster are collected by FluentD and shipped to AWS Elasticsearch. Kibana is then used as an interface to explore those logs, create graphs, dashboards, etc.

If application logs are printed as JSON, FluentD and Elasticsearch should handle automatically parsing and storing the json structure as individual fields, which means if you output a log like `{"myField": "1234"}`, you would be able to write a query in Kibana that looks like `log.myField: "1234"`. This will even handle deeply nested JSON.

It also supports parsing the [Elasticsearch Common Schema](https://www.elastic.co/guide/en/ecs/current/index.html), which is a great way to keep your logging consistent across multiple applications.

You can view the Kibana dashboard at http://kibana.logging.svc.cluster.local/_plugin/kibana after logging into the VPN.


### Elasticsearch retention
Retention in Elasticsearch is controlled by [Index Lifecycle Policies](https://www.elastic.co/guide/en/elasticsearch/reference/current/index-lifecycle-management.html) and constrained by the amount of nodes and storage available in the cluster. Index policies are automatically configured when the cluster is created, and are slightly different between staging and production. The Production policy has a longer retention period, including a period where indices are kept "warm". The Staging policy keeps logs "hot" for a day and then deletes them after a month by default.

These policies may need to be changed, depending on how many logs are being generated. They can be found in [/scripts/files/](/scripts/files/) along with some helper scripts, or you can see them in the Kibana UI in the "Index Management" section.

Another option would be to increase the number of nodes in the cluster or the size of the attached storage for each node, though both of these actions come with an associated cost. Both of these can be changed by modifying the associated values in Terraform in `/terraform/environments/<env>/main.tf`

# Metrics

## Cloudwatch
More to come...

## Grafana + Prometheus
Prometheus runs in the k8s cluster and collects and stores metrics from various sources.
Grafana also runs in the cluster and connects to various data sources including Prometheus, Cloudwatch, and Elasticsearch, to pull in and visualize data.
It can create graphs, dashboards, and alerts which can be sent out via email, Slack, PagerDuty or many other integrations.

You can view the Grafana dashboard at http://grafana.metrics.svc.cluster.local after logging into the VPN.
The default username is 'admin' and the password is '<% .Name %>'. This account could be shared across multiple team members, you could create mulitple accounts per-person or -team, or you could add an external auth provider like Google.

The UIs for Grafana and Kibana are only available from inside the private network (via the VPN) so there is already a certain amount of access restriction.


### Default dashboards
There should be a handful of default dashboards that get created by the various prometheus components. For example, there are a number of dashboards related to Kubernetes nodes, workloads, etc.
There's also a site full of (community-created dashboards)[https://grafana.com/grafana/dashboards] which are very useful to get started, and to use as an example. Just copy the ID, click Create > Import Dashboard in Grafana, and paste the id into the box!

Here are some useful ones:
- [NGINX Ingress controller](https://grafana.com/grafana/dashboards/9614)
- [AWS RDS](https://grafana.com/grafana/dashboards/707)
- [Kubernetes Nodes](https://grafana.com/grafana/dashboards/1860)
- [Elasticsearch](https://grafana.com/grafana/dashboards/6483)


### Adding Slack integration
The image renderer plugin is already enabled, which allows Grafana to attach an image to the notifications it sends. To add alerts, go into the Alerting > Notification Channels section of Grafana and add a Slack Channel. Fill in the webhook URL. If you want files attached, fill in the "Recipient" channel, "Token", and enable "Include Image"

### Adding Prometheus data sources
There are a number of community-supported exporters available here as helm charts:
https://github.com/prometheus-community/helm-charts/tree/main/charts

### Adding a ServiceMonitor
Prometheus Operator is running in the cluster, which allows you to control the prometheus configuration via native Kubernetes "Custom Resources".
This means if you introduce a new service into the cluster that supports prometheus stat scraping, it is easy to set up. You would need to create a new `ServiceMonitor` in the `metrics` namespace that defines where to find the service that prometheus should watch for stats. It would look something like this:
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: nginx-ingress-controller-metrics    # Name of this monitor, just has to be unique
  namespace: metrics
spec:
  endpoints:
    - interval: 30s
      port: metrics                         # Which port on the service should be hit. A path can also be added
  selector:
    matchLabels:
      app.kubernetes.io/name: ingress-nginx # The label of the service to monitor
  namespaceSelector:
    matchNames:
      - ingress-nginx                       # The namespace to look for a service in
```
