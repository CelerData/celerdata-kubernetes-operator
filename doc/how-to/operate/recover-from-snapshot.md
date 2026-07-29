---
title: Recover a cluster from a snapshot
sidebar_label: Recover from a snapshot
sidebar_position: 4
description: "Walk through a shared-data cluster recovery end to end: snapshot, destroy, restore, and verify."
---

# Recover a cluster from a snapshot

Shared-data clusters support disaster recovery from CelerData 3.4.1 onward. This guide walks
the whole loop end to end: build a cluster, put data in it, snapshot it, destroy it, bring it
back, and confirm the data survived.

There is a lot in this document. The steps come first, in the order you would actually run
them; [what the operator is doing behind them](#what-the-operator-is-doing) is at the end,
once you have watched a recovery happen. Reading the state machine before you have seen the
phases move is harder than reading it after.

Inorder to keep it simple and easy for users to follow this document, we use the `kube-celerdata` Helm Chart to deploy.
Please note:

1. Be sure to use at least v1.10.0 version of Operator and CRD.
2. Be sure to use at least 3.4.1 version of the CelerData image to do disaster recovery.
3. Sensitive information is replaced by xxx, please set it to a reasonable value.

## 1. Create a normal working cluster

Prepare the `./celerdata-values.yaml` file:
> Note: we set `automated_cluster_snapshot_interval_seconds` to configure every minute to take a snapshot.

```yaml
operator:
  celerDataOperator:
    image:
      repository: us-west1-docker.pkg.dev/phrasal-verve-350013/celerdata/operator
      tag: v1.10.0
    imagePullPolicy: IfNotPresent
    replicaCount: 1
    resources:
      requests:
        cpu: 1m
        memory: 20Mi
celerdata:
  celerDataCluster:
    enabledBe: false
    enabledCn: true
  celerDataCnSpec:
    config: |
      sys_log_level = INFO
      # ports for admin, web, heartbeat service
      thrift_port = 9060
      webserver_port = 8040
      heartbeat_service_port = 9050
      brpc_port = 8060
    image:
      repository: us-west1-docker.pkg.dev/phrasal-verve-350013/celerdata/cn-ubuntu
      tag: 3.4.1
    replicas: 1
    resources:
      limits:
        cpu: 8
        memory: 8Gi
      requests:
        cpu: 1m
        memory: 10Mi
    storageSpec:
      name: cn
      logStorageSize: 1Gi
      storageSize: 10Gi
  celerDataFeSpec:
    feEnvVars:
      - name: LOG_CONSOLE
        value: "1"
    config: |
      LOG_DIR = ${STARROCKS_HOME}/log
      DATE = "$(date +%Y%m%d-%H%M%S)"
      JAVA_OPTS="-Dlog4j2.formatMsgNoLookups=true -Xmx8192m -XX:+UseG1GC -Xlog:gc*:${LOG_DIR}/fe.gc.log.$DATE:time -XX:ErrorFile=${LOG_DIR}/hs_err_pid%p.log -Djava.security.policy=${STARROCKS_HOME}/conf/udf_security.policy"
      http_port = 8030
      rpc_port = 9020
      query_port = 9030
      edit_log_port = 9010
      mysql_service_nio_enabled = true
      sys_log_level = INFO
      run_mode = shared_data
      cloud_native_meta_port = 6090
      enable_load_volume_from_conf = true
      cloud_native_storage_type = S3
      aws_s3_path = xxx
      aws_s3_region = xxx
      aws_s3_endpoint = xxx
      aws_s3_access_key = xxx
      aws_s3_secret_key = xxx
      # we add this configuration because we want to get cluster snapshot quickly
      automated_cluster_snapshot_interval_seconds = 60
    replicas: 3
    image:
      repository: us-west1-docker.pkg.dev/phrasal-verve-350013/celerdata/fe-ubuntu
      tag: 3.4.1
    resources:
      limits:
        cpu: 2
        memory: 4Gi
      requests:
        cpu: 1m
        memory: 20Mi
    storageSpec:
      logStorageSize: 1Gi
      name: fe-storage
      storageSize: 10Gi
```

Create the cluster using Helm:

```bash
helm install -f ./celerdata-values.yaml celerdata celerdata-community/kube-celerdata

# make sure the cluster has been successfully deployed
kubectl get pods
NAME READY STATUS RESTARTS AGE
kube-celerdata-cn-0 1/1 Running 0 23s
kube-celerdata-fe-0 1/1 Running 0 79s
kube-celerdata-fe-1 1/1 Running 0 79s
kube-celerdata-fe-2 1/1 Running 0 79s
```

## 2. Create a table and insert data

Connect to the FE Pod:

```bash
# enter FE pod
kubectl exec -it kube-celerdata-fe-0 bash

# use mysql client to login
mysql -h 127.0.0.1 -P9030 -uroot
...
mysql>    
```

Execute the following SQL statement:

```sql
CREATE
DATABASE IF NOT EXISTS quickstart;

USE
quickstart;

-- create table
CREATE TABLE source_wiki_edit
(
    event_time     DATETIME,
    channel        VARCHAR(32)  DEFAULT '',
    user           VARCHAR(128) DEFAULT '',
    is_anonymous   TINYINT      DEFAULT '0',
    is_minor       TINYINT      DEFAULT '0',
    is_new         TINYINT      DEFAULT '0',
    is_robot       TINYINT      DEFAULT '0',
    is_unpatrolled TINYINT      DEFAULT '0',
    delta          INT          DEFAULT '0',
    added          INT          DEFAULT '0',
    deleted        INT          DEFAULT '0'
) DUPLICATE KEY(
   event_time,
   channel,user,
   is_anonymous,
   is_minor,
   is_new,
   is_robot,
   is_unpatrolled
)
PARTITION BY RANGE(event_time)(
PARTITION p06 VALUES LESS THAN ('2015-09-12 06:00:00'),
PARTITION p12 VALUES LESS THAN ('2015-09-12 12:00:00'),
PARTITION p18 VALUES LESS THAN ('2015-09-12 18:00:00'),
PARTITION p24 VALUES LESS THAN ('2015-09-13 00:00:00')
)
DISTRIBUTED BY HASH(user);

-- insert data
INSERT INTO source_wiki_edit
VALUES ("2015-09-12 00:00:00", "#en.wikipedia", "AustinFF", 0, 0, 0, 0, 0, 21, 5, 0),
       ("2015-09-12 00:00:00", "#ca.wikipedia", "helloSR", 0, 1, 0, 1, 0, 3, 23, 0),
       ("2015-09-12 08:00:00", "#ca.wikipedia", "helloSR", 0, 1, 0, 1, 0, 3, 23, 0);

-- select data
select *
from source_wiki_edit;
```

## 3. Generate Cluster Snapshot

Begin backup:

```sql
mysql
> ADMIN SET AUTOMATED CLUSTER SNAPSHOT ON STORAGE VOLUME builtin_storage_volume;
Query
OK, 0 rows affected (0.10 sec)
```

Wait for the backup to complete:

```sql
SELECT *
FROM INFORMATION_SCHEMA.CLUSTER_SNAPSHOT_JOBS \ G;
SNAPSHOT_NAME
: automated_cluster_snapshot_1739864377140
       JOB_ID: 13018
 CREATED_TIME: 2025-02-18 15:39:37
FINISHED_TIME: 2025-02-18 15:40:27
        STATE: FINISHED
  DETAIL_INFO:
ERROR_MESSAGE:

mysql>
SELECT *
FROM INFORMATION_SCHEMA.CLUSTER_SNAPSHOTS \ G;
*
************************** 1. row ***************************
     SNAPSHOT_NAME: automated_cluster_snapshot_1739864488333
     SNAPSHOT_TYPE: AUTOMATED
      CREATED_TIME: 2025-02-18 15:41:28
     FE_JOURNAL_ID: 1776
STARMGR_JOURNAL_ID: 126
        PROPERTIES:
    STORAGE_VOLUME: builtin_storage_volume
      STORAGE_PATH: s3://xxx/data/7351ce6a-f4a4-4937-a876-cb8801085aea/meta/image/automated_cluster_snapshot_1739864488333
1 row in set (0.03 sec)
```

Please note: because we set the backup interval to 1 minute, the backup path may be different from the above. The final
result can be viewed through s3:

```bash
s3cmd ls s3://xxx/data/7351ce6a-f4a4-4937-a876-cb8801085aea/meta/image/

sDIR s3://xxx/data/7351ce6a-f4a4-4937-a876-cb8801085aea/meta/image/automated_cluster_snapshot_1739858235830/
```

## 4. Delete the created cluster

```bash
helm uninstall celerdata

# delete pvcs
kubectl get pvc | awk '{if (NR>1){print $1}}' | xargs kubectl delete pvc
persistentvolumeclaim "cn-data-kube-celerdata-cn-0" deleted
persistentvolumeclaim "cn-log-kube-celerdata-cn-0" deleted
persistentvolumeclaim "fe-storage-log-kube-celerdata-fe-0" deleted
persistentvolumeclaim "fe-storage-log-kube-celerdata-fe-1" deleted
persistentvolumeclaim "fe-storage-log-kube-celerdata-fe-2" deleted
persistentvolumeclaim "fe-storage-meta-kube-celerdata-fe-0" deleted
persistentvolumeclaim "fe-storage-meta-kube-celerdata-fe-1" deleted
persistentvolumeclaim "fe-storage-meta-kube-celerdata-fe-2" deleted
```

## 5. Create a new cluster for disaster recovery

We will reuse the previous `celerdata-values.yaml` file, so be sure to ensure the security of this configuration file.
Prepare a new file named `override.yaml`, which contains the configuration required for disaster recovery.

```yaml
celerdata:
  celerDataCluster: # enable disaster recovery
    disasterRecovery:
      enabled: true
      generation: 1
  celerDataFeSpec: # mount the cluster_snapshot.yaml
    configMaps:
      - name: cluster-snapshot
        mountPath: /opt/starrocks/fe/conf/cluster_snapshot.yaml
        subPath: cluster_snapshot.yaml

  configMaps:
    - name: cluster-snapshot
      data:
        cluster_snapshot.yaml: |
          # information about the cluster snapshot to be downloaded and restored
          cluster_snapshot:
              cluster_snapshot_path: s3://xxx/data/7351ce6a-f4a4-4937-a876-cb8801085aea/meta/image/automated_cluster_snapshot_1739858235830
              storage_volume_name: builtin_storage_volume

          # Operator will add the other FE followers automatically
          # just leave it blank
          frontends:

          # Operator will add the CN nodes automatically
          # just leave it blank
          compute_nodes:

          # used for restoring a cloned snapshot
          storage_volumes:
            - name: builtin_storage_volume
              type: S3
              location: s3://xxx/data
              comment: my s3 volume
              properties:
                - key: aws.s3.region
                  value: xxx
                - key: aws.s3.endpoint
                  value: xxx
                - key: aws.s3.access_key
                  value: xxx
                - key: aws.s3.secret_key
                  value: xxx
```

This time, we will deploy the cluster with the following command:

```bash
# Note:
# 1. make sure you are using the at least v1.10.0 version of Operator and CRD
# 2. the command to deploy the cluster is different from the first time. We specify two files, and the override.yaml
#    is used for the recovery configuration.
helm install -f ./celerdata-values.yaml -f override.yaml celerdata celerdata-community/kube-celerdata --version 1.10.0

```

The detailed process of disaster recovery is as follows:

1. The Operator will start a FE Pod and start the disaster recovery.

   ```bash
   kubectl get pods
   NAME                  READY   STATUS    RESTARTS        AGE
   kube-celerdata-fe-0   1/1     Running   0               4m37s
   ```

   If you check the status of the CelerDataCluster at this time, you will see:

   ```bash
   kubectl get cdc kube-celerdata -oyaml | less
   status:
     phase: running
     disasterRecovery:
       observedGeneration: 1
       phase: doing
       reason: disaster recovery is in progress
       startTimestamp: "1739860263"
   ```

2. After the disaster recovery is complete, the Operator will automatically start other Pods.

   ```bash
   kubectl get pods
   NAME                  READY   STATUS    RESTARTS        AGE
   kube-celerdata-cn-0   1/1     Running   0               7m54s
   kube-celerdata-fe-0   1/1     Running   0               7m1s
   kube-celerdata-fe-1   1/1     Running   0               7m54s
   kube-celerdata-fe-2   1/1     Running   0               7m54s
   ```

   The cluster status is as follows:

   ```bash
   status:
     phase: running
     disasterRecoveryStatus:
       endTimestamp: 1739861262
       observedGeneration: 1
       phase: done
       reason: disaster recovery is done
       startTimestamp: 1739860263
   ```

## Verify the recovery

```shell
# enter the pod
kubectl exec -it kube-celerdata-fe-0 bash

# connect mysql
mysql -h 127.0.0.1 -P9030 -uroot

# get the data

mysql >USE quickstart
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql >select * from source_wiki_edit
```

## What the operator is doing

You have now watched a cluster come back from a snapshot. Here is the machinery underneath.

### The two fields you set

Recovery is driven by `spec.disasterRecovery`, and reported through
`status.disasterRecoveryStatus`:

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

`generation` is the reason a recovery is a deliberate act rather than something that repeats
on every reconcile. It is a counter you increment; `observedGeneration` records the last one
the operator acted on. A recovery starts when `disasterRecoveryStatus` is empty or
`observedGeneration < generation`. Once they match and the phase is `done`, the operator
leaves the cluster alone — so the recovery manifest can stay applied without re-triggering.
To recover again, increment `generation` again.

Before starting, the operator also checks that `enabled` is true and that FE's configuration
puts the cluster in shared-data mode. Recovery only makes sense when the data is in object
storage rather than on the BE nodes.

### Why only FE restarts

During recovery the operator pauses reconciliation of BE and CN entirely. Nothing is
recovered onto them, because in shared-data mode they hold no authoritative data — the
snapshot restores FE's metadata, and the data itself is already in object storage.

For FE, the operator rewrites the StatefulSet:

- **One replica.** Restoring metadata into several FE nodes at once would leave them
  disagreeing about what was restored.
- **`RESTORE_CLUSTER_GENERATION` and `RESTORE_CLUSTER_SNAPSHOT` injected.** The first tells
  the pod which generation it belongs to, so a pod from a previous attempt is not mistaken
  for this one. The second is what actually triggers FE's restore.
- **Startup and liveness probes removed.** Restoring can take a long time, and a liveness
  probe would decide the container had hung and kill it partway through.
- **The readiness probe changed** from an HTTP request on 8030 to a connection check on 9030,
  which is the earliest reliable signal that FE has finished restoring.

That probe swap is why the mounted `cluster_snapshot.yaml` matters: the operator checks it is
present — matching on the `SubPath` field — before it will start, because without it FE has
nothing to restore from.

Once the FE pod is ready, the operator restores the normal StatefulSet from your
`CelerDataCluster` spec and resumes BE and CN.

### Reading the phase

`disasterRecoveryStatus.phase` moves `todo` → `doing` → `done`. It enters `todo` when the
operator first notices the request, `doing` once the modified StatefulSet is applied, and
`done` after the FE pod reports ready and belongs to the current generation. Time spent in
`doing` is the restore itself, so on a large cluster expect to sit there a while — that is
the phase to watch, and `reason` is where a failure explains itself.

For the same material without the procedure wrapped around it, see
[Disaster recovery](../../explanation/disaster-recovery.md).
