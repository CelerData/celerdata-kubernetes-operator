# Automatic scaling for CN nodes

This topic describes how to configure automatic scaling for CN nodes in a PhoenixAI cluster.
> Note: If you are seeking for help for versions before v1.11.0, this doc is for you. If you are using v1.11.0 or later, please refer to the [HPA Dynamic Scaling](./hpa_dynamic_scaling_with_helm_howto.md) doc.

## Prerequisites

- Ensure that you have installed the Kubernetes cluster. v1.23.0+ is recommended.
- Ensure that you have installed the [Helm](https://helm.sh/) package manager. 3.0.0+ is recommended.
- Ensure that the helm chart repo for PhoenixAI is added.
  See [Add the Helm Chart Repo for PhoenixAI](../GetStarted/add_helm_repo_howto.md).
- Ensure that you have deployed a PhoenixAI cluster.
  See [Deploy PhoenixAI With Operator](../Deploy/deploy_phoenixai_with_operator_howto.md)
  or [Deploy PhoenixAI With Helm](../Deploy/deploy_phoenixai_with_helm_howto.md)
  to learn how to deploy a PhoenixAI cluster.
- Ensure that you have installed [metrics-server](https://github.com/kubernetes-sigs/metrics-server).

> Suppose you have installed a PhoenixAI cluster named phoenixaicluster-sample under the phoenixai namespace

There are two ways to deploy PhoenixAI cluster:

1. Deploy PhoenixAI cluster with `PhoenixAICluster` CR yaml.
2. Deploy PhoenixAI cluster with Helm chart.

Therefore, there are two ways to configure automatic scaling for CN nodes.

You can specify the resource metrics for CNs, such as average CPU utilization, average memory
usage, elastic scaling threshold, upper elastic scaling limit, and lower elastic scaling limit. The upper elastic
scaling limit and lower elastic scaling limit specify the maximum number and minimum number of CNs allowed for elastic
scaling.

## Configure automatic scaling for CN nodes by using CR yaml

Run the command `kubectl -n phoenixai edit pac phoenixaicluster-sample`` to configure the automatic scaling policy for
CN nodes.

> **NOTE**
>
> If you have configured the automatic scaling policy for the CN cluster, delete the `replicas` field from the
> `phoenixAICnSpec` in the PhoenixAI cluster configuration file.

The following is a [template](../../examples/phoenixai/deploy_a_phoenixai_cluster_with_cn.yaml) to help you configure
automatic scaling policies:

```YAML
  phoenixAICnSpec:
    image: us-west1-docker.pkg.dev/phoenix-ai-images/enterprise/cn-ubuntu:4.1-latest
    requests:
      cpu: 4
      memory: 4Gi
    autoScalingPolicy: # Automatic scaling policy of the CN cluster.
      maxReplicas: 10 # The maximum number of CNs is set to 10.
      minReplicas: 1 # The minimum number of CNs is set to 1.
      hpaPolicy:
        metrics: # Resource metrics
          - type: Resource
            resource:
              name: memory # The average memory usage of CNs is specified as a resource metric.
              target:
                averageUtilization: 30
                # The elastic scaling threshold is 30%.
                # When the average memory utilization of CNs exceeds 30%, the number of CNs increases for scale-out.
                # When the average memory utilization of CNs is below 30%, the number of CNs decreases for scale-in.
                type: Utilization
          - type: Resource
            resource:
              name: cpu # The average CPU utilization of CNs is specified as a resource metric.
              target:
                averageUtilization: 60
                # The elastic scaling threshold is 60%.
                # When the average CPU utilization of CNs exceeds 60%, the number of CNs increases for scale-out.
                # When the average CPU utilization of CNs is below 60%, the number of CNs decreases for scale-in.
                type: Utilization
        behavior: #  The scaling behavior is customized according to business scenarios, helping you achieve rapid or slow scaling or disable scaling.
          scaleUp:
            policies:
              - type: Pods
                value: 1
                periodSeconds: 10
          scaleDown:
            selectPolicy: Disabled
```

## Configure automatic scaling for CN nodes by using Helm chart

Add the following snippets to `values.yaml` to configure the automatic scaling policy for CN nodes,

```YAML
  phoenixAICluster: # do not forget to set enabledCn to true to enable deployment of CNs.
    enabledCn: true

  phoenixAICnSpec:
    image:
      repository: us-west1-docker.pkg.dev/phoenix-ai-images/enterprise/cn-ubuntu
      tag: 4.1-latest
    resources:
      requests:
        cpu: 4
        memory: 4Gi
    autoScalingPolicy:
      minReplicas: 1
      maxReplicas: 10
      hpaPolicy:
        metrics: # Resource metrics
          - type: Resource
            resource:
              name: memory # The average memory usage of CNs is specified as a resource metric.
              target:
                averageUtilization: 30
                # The elastic scaling threshold is 30%.
                # When the average memory utilization of CNs exceeds 30%, the number of CNs increases for scale-out.
                # When the average memory utilization of CNs is below 30%, the number of CNs decreases for scale-in.
                type: Utilization
          - type: Resource
            resource:
              name: cpu # The average CPU utilization of CNs is specified as a resource metric.
              target:
                averageUtilization: 60
                # The elastic scaling threshold is 60%.
                # When the average CPU utilization of CNs exceeds 60%, the number of CNs increases for scale-out.
                # When the average CPU utilization of CNs is below 60%, the number of CNs decreases for scale-in.
                type: Utilization
        behavior: #  The scaling behavior is customized according to business scenarios, helping you achieve rapid or slow scaling or disable scaling.
          scaleUp:
            policies:
              - type: Pods
                value: 1
                periodSeconds: 10
          scaleDown:
            selectPolicy: Disabled
```

## Fields description

The following are descriptions of a few important fields:

- The upper and lower limits for elastic scaling.

  ```YAML
  maxReplicas: 10 # The maximum number of CNs is set to 10.
  minReplicas: 1 # The minimum number of CNs is set to 1.
  ```

- The threshold for elastic scaling.

  ```YAML
  # For example, the average CPU utilization of CNs is specified as a resource metric.
  # The elastic scaling threshold is 60%.
  # When the average CPU utilization of CNs exceeds 60%, the number of CNs increases for scale-out.
  # When the average CPU utilization of CNs is below 60%, the number of CNs decreases for scale-in.
  - type: Resource
    resource:
      name: cpu
      target:
        averageUtilization: 60
        type: Utilization
  ```

- The `behavior` for elastic scaling.

  Kubernetes also supports using `behavior` to customize scaling behaviors according to business scenarios, helping you
  achieve rapid or slow scaling or disable scaling. For more information about automatic scaling policies,
  see [Horizontal Pod Scaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/).
