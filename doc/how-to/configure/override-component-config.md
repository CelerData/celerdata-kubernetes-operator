---
title: Override component configuration files
sidebar_label: Override component config
sidebar_position: 5
description: Replace the default fe.conf, be.conf, or cn.conf shipped in the images by using a ConfigMap.
---

# Override component configuration files

The official images contains default application configuration file, however, they can be overwritten by configuring
kubernetes configmap deployment crd.

You can generate the configmap from an CelerData configuration file.
Below is an example of creating a Kubernetes configmap `fe-config-map` from the `fe.conf` configuration file. You can do
the same with BE and CN.

```console
# create fe-config-map from starrocks/fe/conf/fe.conf file
kubectl create configmap fe-config-map --from-file=starrocks/fe/conf/fe.conf
```

Once the configmap is created, you can reference the configmap in the yaml file.
For example:

```yaml
# fe use configmap example
celerDataFeSpec:
  configMapInfo:
    configMapName: fe-config-map
    resolveKey: fe.conf
# cn use configmap example
celerDataCnSpec:
  configMapInfo:
    configMapName: cn-config-map
    resolveKey: cn.conf
  # be use configmap example
  celerDataBeSpec:
    configMapInfo:
    configMapName: be-config-map
    resolveKey: be.conf
```

To mount arbitrary extra files instead of replacing a component config file, see
[Mount external ConfigMaps or Secrets](./mount-external-configmaps-or-secrets.md).
