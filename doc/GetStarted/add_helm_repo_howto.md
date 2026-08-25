# Add the Helm Chart Repo for PhoenixAI

1. Add the Helm Chart Repo.

   ```Bash
   helm repo add phoenixai https://celerdata.github.io/phoenixai-kubernetes-operator
   ```

2. Update the Helm Chart Repo to the latest version.

   ```Bash
   helm repo update phoenixai
   ```

3. View the Helm Chart Repo that you added.

   ```Bash
   $ helm search repo phoenixai
   NAME                       CHART VERSION    APP VERSION  DESCRIPTION
   phoenixai/kube-anywhere    2.0.0            4.1-latest   kube-anywhere includes three subcharts, operato...
   phoenixai/operator         2.0.0            2.0.0        A Helm chart for PhoenixAI operator
   phoenixai/phoenixai        2.0.0            4.1-latest   A Helm chart for PhoenixAI cluster
   phoenixai/anywhere         2.0.0            v2.0.0       A Helm chart for PhoenixAI Anywhere — a read-on...
   phoenixai/warehouse        2.0.0            4.1-latest   Warehouse is currently a feature of the Phoenix...
   ```

See [Deploy PhoenixAI With Helm](../Deploy/deploy_phoenixai_with_helm_howto.md) to learn how to deploy PhoenixAI with Helm.
