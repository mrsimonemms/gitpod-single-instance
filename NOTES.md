<!--
Please put the latest comment first in format:
"
---
<Date>: <Username>

<Comment>
"
-->
---
2022-01-11: jimmybrancaccio

Worked on and I believe succeeded in resolving the issue with the `proc` mounting. I removed the `mountPropagation` lines from `out.yaml` file. There were 3-4 of them in the container spec section for the `ws-daemon DaemonSet`. Source [here](https://github.com/rancher/k3d/issues/429), [here](https://github.com/rancher/k3d/discussions/479) and [here](https://github.com/kubernetes/kubernetes/issues/61058).

I've updated the `kubeconfig:` section in the `k3d.yaml` file so that it saves a copy of the Kubernetes cluster configuration locally.

I've updated the `README.md` file with some getting started steps for Linux.

---
2021-12-19: MrSimonEmms

First attempt.

A custom Dockerfile is used because `/bin/bash` is required on the host image -
see https://github.com/rancher/k3d/issues/901 for more details

`ws-daemon` is still problematic. The current setup gives this error on `kubectl describe`

```
Error: failed to generate container "05d49e4e3bc66a93066252d70a1220ddba0d4990996c9a21658a09884cbff36f" spec: failed to generate spec: path "/proc/49/mounts" is mounted on "/proc" but it is not a shared or slave mount
```

If I add the volume `/proc:/proc`, the folder `/run/k3s/containerd/io.containerd.runtime.v2.task/k8s.io`
doesn't get mounted which is peculiar.

Thoughts anyone?
