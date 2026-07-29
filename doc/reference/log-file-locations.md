---
title: Log file locations
sidebar_label: Log file locations
sidebar_position: 4
description: Where the FE, BE, and CN components write their log files inside the container.
---

# Log file locations

Each component writes its logs inside its own container:

1. The FE component's logs are located in: `/opt/starrocks/fe/log`, with key logs
   including: `fe.out`, `fe.log`, `fe.warn.log`.
2. The BE component's logs are located in: `/opt/starrocks/be/log`, with key logs
   including: `be.out`, `be.INFO`, `be.WARNING`.
3. The CN component's logs are located in: `/opt/starrocks/cn/log`, with key logs
   including: `cn.out`, `cn.INFO`, `cn.WARNING`.

By default these live on an `emptyDir` volume and are lost when the pod restarts — see
[Logging](../explanation/logging.md) for why, and
[Configure logging](../how-to/configure/configure-logging.md) to change it.
