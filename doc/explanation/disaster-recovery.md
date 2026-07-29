---
title: Disaster recovery
sidebar_label: Disaster recovery
sidebar_position: 8
description: "How the operator drives shared-data cluster recovery: the spec and status fields, what triggers a run, and the phase state machine."
---

# Disaster recovery

From CelerData 3.4.1, the shared-data mode cluster supports disaster recovery. The Operator can configure the disaster
recovery for the shared-data mode cluster to ensure the data security and high availability.

This page explains the mechanism. For the procedure, see
[Recover a cluster from a snapshot](../how-to/operate/recover-from-snapshot.md).

## The API surface

Operator adds the following fields:

```yaml
spec:
  disasterRecovery:
    generation: 1
    enabled: true

status:
  disasterRecoveryStatus:
    phase: todo/doing/done
    reason: ""
    observedGeneration: 1
    startTimestamp: xxx   # unix timestamp
    endTimestamp: yyy     # unix timestamp  
```

### What triggers a recovery

1. The `enabled` field must be true.
2. The `generation` is a monotonically increasing integer that represents the expected state (spec) change version of
   the resource object. `observedGeneration` represents the version of the DR operation that has been executed. The
   Operator compares the values of `generation` and `observedGeneration`: when `disasterRecoveryStatus` is empty,
   or `observedGeneration < generation`, a new DR operation is triggered.
   If `generation == observedGeneration` && `disasterRecovery.Phase` != `v1.DRPhaseDone`, it means that after the last
   reconcile, the CelerData cluster has entered disaster recovery mode.
3. Check the FE configuration file to ensure that the CelerData cluster is started in shared-data mode.

If all the above conditions are met, the Operator will enter the DR mode.

### How the operator runs the recovery

For BE component, the reconcile is paused.

For CN component, the reconcile is paused.

The reconcile process for FE is as follows:

1. Traverse `spec.celerDataFeSpec.ConfigMaps` to confirm that `cluster_snapshot.yaml` has been mounted. Currently,
   this check is relatively simple, mainly to check whether the `SubPath` field is equal to `cluster_snapshot.yaml`.
2. Modify the FE Statefulset, including:
    1. Start a single-replica FE.
    2. Inject the `RESTORE_CLUSTER_GENERATION` and `RESTORE_CLUSTER_SNAPSHOT` environment variables. The former is
       used to determine the Generation to which the Pod belongs, and the latter is an environment variable passed to
       the FE module to trigger the disaster recovery operation of the FE Pod.
    3. Delete the startup/liveness configuration because the DR operation will take a long time.
    4. Modify the Readiness configuration. The configuration for normal cluster is to send an HTTP request to FE 8030;
       the new configuration is used to detect whether the FE 9030 port is connected. Once connected, it means that the
       FE Pod disaster recovery operation is complete.
3. After the FE Pod disaster recovery is complete, according to the configuration of the CelerDataCluster, CelerData
   is started normally.

### How the phase is updated

What is the phase of disaster recovery? In the status, `disasterRecoveryStatus.phase` represents the phase of the
disaster recovery, including `todo`, `doing`, `done`.

The status update logic is as follows:

1. The Operator detects that the disaster recovery mode is first entered (disasterRecoveryStatus is empty) or
   `observedGeneration < generation`. Then the disaster recovery mode enters the `todo` phase.
2. After the modified Statefulset is applied, update `disasterRecoveryStatus.phase` to the `doing` state. The duration
   of this state depends on the time it takes to complete the disaster recovery.
3. The Operator periodically checks the status of the FE Pod. First, confirm the `generation` to which it belongs;
   second, confirm whether the Pod is Ready.
4. After the FE Pod is Ready, update `disasterRecoveryStatus.phase` to the `done` mode.
