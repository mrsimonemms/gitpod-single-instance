<!--
Please put the latest comment first in format:
"
---
<Date>: <Username>

<Comment>
"
-->

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
