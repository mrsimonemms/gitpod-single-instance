# @link https://github.com/k3s-io/k3s/blob/master/package/Dockerfile
ARG K3S_VERSION=v1.21.7-k3s1
FROM rancher/k3s:${K3S_VERSION} AS k3s

FROM alpine
COPY --from=k3s / /
RUN apk add --no-cache bash

# This is as per-the parent image
RUN chmod 1777 /tmp
VOLUME /var/lib/kubelet
VOLUME /var/lib/rancher/k3s
VOLUME /var/lib/cni
VOLUME /var/log
ENV PATH="$PATH:/bin/aux"
ENV CRI_CONFIG_FILE="/var/lib/rancher/k3s/agent/etc/crictl.yaml"
ENTRYPOINT ["/bin/k3s"]
CMD ["agent"]
