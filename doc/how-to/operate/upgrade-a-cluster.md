---
title: Upgrade a cluster
sidebar_label: Upgrade a cluster
sidebar_position: 2
description: Roll BE and FE nodes onto a new image version by patching the CelerDataCluster resource.
---

# Upgrade a cluster

Upgrade a running cluster by pointing the BE and FE specs at a new image.

## Upgrade BE nodes

Run the following command to specify a new BE image file, such as `us-west1-docker.pkg.dev/phrasal-verve-350013/celerdata/be-ubuntu:latest`:

```bash
kubectl -n celerdata patch celerdatacluster celerdatacluster-sample --type='merge' -p '{"spec":{"celerDataBeSpec":{"image":"us-west1-docker.pkg.dev/phrasal-verve-350013/celerdata/be-ubuntu:latest"}}}'
```

## Upgrade FE nodes

Run the following command to specify a new FE image file, such as `us-west1-docker.pkg.dev/phrasal-verve-350013/celerdata/fe-ubuntu:latest`:

```bash
kubectl -n celerdata patch celerdatacluster celerdatacluster-sample --type='merge' -p '{"spec":{"celerDataFeSpec":{"image":"us-west1-docker.pkg.dev/phrasal-verve-350013/celerdata/fe-ubuntu:latest"}}}'
```

The upgrade process lasts for a while. You can run the command `kubectl -n celerdata get pods` to view the upgrade
progress.
