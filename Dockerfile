ARG K3S_VERSION=v1.22.6-k3s1
FROM rancher/k3s:${K3S_VERSION} AS k3s
RUN rm /bin/sh

FROM ubuntu:20.04
RUN apt-get update \
  && apt-get install -y ca-certificates systemctl \
  && mkdir -p /etc \
  && echo 'hosts: files dns' > /etc/nsswitch.conf \
  && chmod 1777 /tmp \
  && mkdir -p /var/lib/rancher/k3s/agent/etc/containerd/
# Must come after the RUN step
COPY --from=k3s /bin /bin
VOLUME /var/lib/kubelet
VOLUME /var/lib/rancher/k3s
VOLUME /var/lib/cni
VOLUME /var/log
ENV PATH="$PATH:/bin/aux"
ENV CRI_CONFIG_FILE="/var/lib/rancher/k3s/agent/etc/crictl.yaml"
ENTRYPOINT ["/bin/k3s"]
CMD ["agent"]
