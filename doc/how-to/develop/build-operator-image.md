---
title: Build the operator image
sidebar_label: Build the operator image
sidebar_position: 1
description: Build and push your own operator container image.
---

# Build the operator image

The official operator image is published to
`us-west1-docker.pkg.dev/phrasal-verve-350013/celerdata/operator`. Build your own only if
you need a change that is not in a release yet.

## Build the image

Follow below instructions if you want to build your own image.

```console
DOCKER_BUILDKIT=1 docker build -t us-west1-docker.pkg.dev/phrasal-verve-350013/celerdata/operator:<tag> .
```

E.g.

```console
DOCKER_BUILDKIT=1 docker build -t us-west1-docker.pkg.dev/phrasal-verve-350013/celerdata/operator:latest .
```

## Push the image

```console
docker push us-west1-docker.pkg.dev/phrasal-verve-350013/celerdata/operator:<tag>
```

E.g.

```console
docker push us-west1-docker.pkg.dev/phrasal-verve-350013/celerdata/operator:latest
```
