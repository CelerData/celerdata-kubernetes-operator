---
title: Storage classes
sidebar_label: Storage classes
sidebar_position: 3
description: The special storageClassName values the operator recognises in addition to real Kubernetes StorageClasses.
---

# Storage classes

Normally, the `storageClassName` is the name of the StorageClass that you want to use for the PersistentVolumeClaim.
We have also provided some special `storageClassName` for you to use:

1. `emptyDir`. It is a good choice when you want to mount a volume into the container for temporary usage, e.g. /tmp. Be aware that the files and directories written to the volume will be completely lost upon container restarting.
2. `hostPath`. It is a good choice when you want to the host's storage for the container, the data will be still there as along as the container is still running on the host. The data will be unavailable upon the container rescheduling to a different host. The typical scenario is to use it as cache volume. The `hostPath` field is required when this type is used.
   field.
   e.g.:
    ```yaml
        storageVolumes:
        - name: cn-cache
          storageClassName: "hostPath"
          hostPath:
            path: /storage
          mountPath: /storage   
    ```

> Note: In both cases, the `storageSize` field will be ignored.
