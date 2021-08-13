---
title: Operating your Kubernetes Cluster
sidebar_label: Kubernetes Cluster operations
sidebar_position: 2
---
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Kubernetes resources

(kubectl has been aliased to k in these examples: `alias k=kubectl`)

## Connecting to a pod

Find the pod you want to connect to:

```shell
k get pods
```

Find the name of the pod you want to connect to, then run `exec`:

```shell
k exec -it <pod name> -- sh
```

You should now be connected to the pod. _Note that this won't work in some cases if the container doesn't have a shell binary in it._

## Logs

You can stream the logs from a pod directly to your local machine:

```shell
k logs <pod id> -f
```

You can also stream the logs from an entire group of pods (such as a deployment):

```shell
k logs deployment/something -f --since=5m
```

Another useful application is `stern` which makes it easy to stream logs in a nice format from multiple pods:
```shell
stern <partial pod id>
```

## Port Forwarding

You can use port forwarding between your local machine and a pod or service.
This can be helpful for debugging by allowing you to `curl` a service directly from your local machine, for example.

Find pods:

```shell
k get pods
```

Find services:

```shell
k get services
```

Forward port to a specific pod:

```shell
k port-forward pod/something-cf99bd9d6-wx9h4 8080:3000
curl localhost:8080
```

_Or_ forward port to a service:

```shell
k port-forward service/something 8080:80
curl localhost:8080
```

## Useful utils

- Stern - tail logs from many containers at once
    - `brew install stern`
    - `stern <service name>`
- Kustomize - used during deployment to build and overlay k8s manifests
    - `brew install kustomize`
- Lens - desktop k8s dashboard / GUI
    - [https://k8slens.dev/](https://k8slens.dev/)
- Autocomplete - There is auto completion of commands and cluster resources for most shells
    - bash - `source <(k completion bash)`
    - zsh - `source <(k completion zsh)`
- Ingress Nginx kubectl [plugin](https://kubernetes.github.io/ingress-nginx/kubectl-plugin/) ( useful to introspect nginx conf and issues )
    - Install [krew](https://github.com/GoogleContainerTools/krew)
    - `k krew install ingress-nginx`
    - `k ingress-nginx --help`

## Useful commands

- Start a bash shell (or any other command) inside an already-running pod
    - `k exec -it <pod name> bash`
    - _Note that if bash is not installed in the container you may need to start another shell like sh._
- Start an arbitrary container in the cluster
    - This can be very useful to start a container within a namespace to be able to connect to other services
    - `k run -it --image ubuntu bash`
- Inspect deployments / pods / services
    - Useful to be able to quickly check issues (env var / image tag) with Kubernetes objects
    - You can also specify a service or a deployment instead of a pod
    - `k describe pod <pod name>`
- Restart the pods in a deployment (for example, after changing volume mounted `configmap`)
    - As long as there are more than 1 pod, this will do a rolling restart which means you should keep serving traffic as normal
    - `k rollout restart deployment <deployment name>`

## How do I replace a node in the cluster with zero downtime?

Occasionally you may need to replace a node, for example to pre-empt AWS from rebooting it in the case they need to do some maintenance, which can happen occasionally.

This process can vary a bit depending on the amount of free resources you have available in your cluster.

**If you have enough free resources to be able move all the pods from the node you want to replace to other nodes, it is as simple as telling k8s to drain the node and then terminating it:**

- `k get nodes`
- `k drain --ignore-daemonsets <node name>`
    - If it complains that it wants to delete local data for a pod, verify that that is okay and add the flag `--delete-local-data` - This should be fine for pods like `coredns`, `metrics-server` etc, as the data is ephemeral.
- Then terminate the instance in AWS Console. A new one will come up to replace it automatically.


**If you are trying to keep your overhead as low as possible and your cluster wouldn't be able to accomodate reallocating pods from the node, there will be a couple extra steps:**
- Stop the cluster autoscaler from trying to control the cluster size during the process
    - `k scale deployments/cluster-autoscaler -n kube-system --replicas=0`
- Find the name and desired capacity of the auto scaling group you want to change.
    - `aws autoscaling describe-auto-scaling-groups --output text --query 'AutoScalingGroups[].[AutoScalingGroupName,DesiredCapacity]'`
- Find the instance id of the node you want to terminate
    - `aws ec2 describe-instances --output text --query 'Reservations[].Instances[].[InstanceId, PrivateDnsName]' --filters "Name=tag:aws:autoscaling:groupName,Values=<asg name>"`
- Bring up 1 new node
    - `aws autoscaling set-desired-capacity --auto-scaling-group-name <asg name> --desired-capacity <previous desired capacity +1>`
- Wait until the new node appears in the list, the total number of nodes should match the new desired capacity
    - `k get nodes`
- Drain pods onto other nodes in the cluster
    - `k drain --ignore-daemonsets <node name>`
    - If it complains that it wants to delete local data for a pod, verify that that is okay and add the flag `--delete-local-data` - This should be fine for pods like `coredns`, `metrics-server` etc, as the data is ephemeral.
- Terminate the old instance and reduce the desired capacity
    - `aws autoscaling terminate-instance-in-auto-scaling-group --should-decrement-desired-capacity --instance-id <instance id starting with "i-">`
- Wait for the instance to disappear for the node list
- Re-enable the cluster autoscaler
    - `k scale deployments/cluster-autoscaler -n kube-system --replicas=1`

:::note
In the case that you determine you don't want to terminate the instance but you have already drained it, the cluster won't schedule any new pods to that node until you uncordon it:
- `k uncordon <node name>`
:::

## How do I upgrade a cluster to a new version of EKS?

Occasionally you may need to upgrade an EKS cluster. This is usually a pretty painless process and there’s a ton of documentation online about it.

As part of this process you will need to upgrade the cluster itself, and some core components. Kubernetes has various applications that run as deployments or daemonsets in the `kube-system` namespace like `coredns`, `kube-proxy` and the AWS VPC CNI provider called `aws-node`.

This document has great instructions on upgrading all of the different pieces, including listing the appropriate versions of the core components for each version of Kubernetes.

[https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html](https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html)

When doing this from terraform you should be able to go into the tf and change the version of the cluster and addons and apply. It should start the upgrade process, rather than tearing down the cluster and rebuilding it. This will make the cluster inaccessible through the AWS console for about 20 minutes.
:::tip
Everything in the cluster should continue to work normally, serve traffic, etc. during this process because the worker nodes and all your workloads are not affected at this point.
:::

To get the latest version of the EKS addons, you can use these AWS CLI commands:
<Tabs
    values={[
        {label: 'vpc-cni', value: 'vpc-cni'},
        {label: 'kube-proxy', value: 'kube-proxy'},
        {label: 'coredns', value: 'coredns'},
    ]}
>
<TabItem value="vpc-cni">
The item marked with "True" is the default for that version.

```shell
aws eks describe-addon-versions \
--addon-name vpc-cni \
--kubernetes-version <version, e.g. 1.21 > \
--query "addons[].addonVersions[].[addonVersion, compatibilities[].defaultVersion]" \
--output text
```

</TabItem>
<TabItem value="kube-proxy">
The item marked with "True" is the default for that version.

```shell
aws eks describe-addon-versions \
--addon-name kube-proxy \
--kubernetes-version <version, e.g. 1.21 > \
--query "addons[].addonVersions[].[addonVersion, compatibilities[].defaultVersion]" \
--output text
```

</TabItem>
<TabItem value="coredns">
The item marked with "True" is the default for that version.

```shell
aws eks describe-addon-versions \
--addon-name coredns \
--kubernetes-version <version, e.g. 1.21 > \
--query "addons[].addonVersions[].[addonVersion, compatibilities[].defaultVersion]" \
--output text
```

</TabItem>
</Tabs>
The process should be:

- Update the addon versions versions in `<env>/main.tf` to match the correct versions for the new cluster version. See the tabs above or [read the AWS docs here](https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html)
- Update the `eks_cluster_version` in terraform
- Run `terraform apply`
- Update your nodes to the new version
    - `aws eks update-nodegroup-version --cluster-name <cluster name> --nodegroup-name <cluster name>-main` ( if you've made changes, specify the correct node group here)

    OR

    - Go into the AWS EKS console and hit update under Configuration > Compute

This will bring up new nodes, gracefully drain your workloads onto them while preventing new pods from being scheduled to the old ones, then take down the old nodes. If your workloads are set up with multiple replicas there should be no downtime during this process.

:::tip
Sometimes you may need to make changes to node groups that would be destructive to the nodes in your cluster, for example changing the type of instances in the group. In situations like this you can apply in stages where you would add a new node group with a unique name and the new instance types. You can apply to bring up this new group of instances, then remove the old group and apply again. This will make sure you always have sufficient nodes in your cluster to handle your workloads.
:::

## More resources

[https://kubernetes.io/docs/reference/kubectl/cheatsheet/](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

[https://kubernetes.io/docs/tasks/debug-application-cluster/debug-application/#debugging-pods](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-application/#debugging-pods)


