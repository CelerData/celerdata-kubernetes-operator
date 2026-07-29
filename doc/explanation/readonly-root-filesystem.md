---
title: Read-only root filesystem
sidebar_label: Read-only root filesystem
sidebar_position: 7
description: Which directories the FE and BE components write to, and how the operator works around a read-only root filesystem.
---

# Read-only root filesystem

## Why the components fail to start

CelerData has three components: Frontend (FE), Backend (BE), and Compute Node(CN). When the `readOnlyRootFilesystem` is
set to `true`, the components of CelerData cannot start normally. This is because the components of CelerData write data
to the disk, and the `readOnlyRootFilesystem` setting prevents the components from writing data to the disk.

For the FE component, FE writes data to the following directories:

```bash
# in fe directory
drwxr-xr-x 2 root      root      4.0K Nov 19 11:27 plugins
drwxr-xr-x 4 root      root      4.0K Nov 19 11:27 temp_dir

# in fe/bin directory
-rw-r--r-- 1 root      root         2 Nov 19 11:27 fe.pid

# in fe/conf directory
lrwxrwxrwx 1 root      root        30 Nov 19 11:27 fe.conf -> /etc/celerdata/fe/conf/fe.conf
```

For the BE component, BE writes data to the following directories:

```bash
# in be directory
drwxr-xr-x 2 root      root      4.0K Nov 19 11:27 spill

# in be/conf directory
lrwxrwxrwx 1 root      root        30 Nov 19 11:27 be.conf -> /etc/celerdata/be/conf/be.conf

# in be/bin directory
-rw-r----- 1 root      root         3 Nov 19 11:27 be.pid

# in be/lib directory
drwxr-xr-x   2 root      root      4.0K Nov 19 11:27 jdbc_drivers
drwxr-xr-x   2 root      root      4.0K Nov 19 11:27 small_file
drwxr-xr-x 130 root      root      4.0K Nov 19 11:27 udf
drwxr-xr-x   2 root      root      4.0K Nov 19 11:27 udf-runtime
```

## How the workaround works

We create and mount a volume, and in the entrypoint script, we will copy everything from the original directory to the
mounted volume. This way, the components of CelerData can write data to the mounted volume.

> Note: you should use the operator version `v1.9.9` or later.

For the procedure, see
[Run with a read-only root filesystem](../how-to/configure/run-with-readonly-root-filesystem.md).
