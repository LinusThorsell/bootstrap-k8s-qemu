# Worker setup (repeat for each worker in cluster)

## (on jumpbox) download binaries

### crictl

```bash
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.33.0/crictl-v1.33.0-linux-amd64.tar.gz
tar -xvf crictl-v1.33.0-linux-amd64.tar.gz -C kubernetes
rm -rf crictl-v1.33.0-linux-amd64.tar.gz
scp kubernetes/crictl root@worker-1:/usr/local/bin
```

FIXME: check that this is actually how you install containerd, seems little off. multiple files/dirs in tarball?
```bash
wget https://github.com/containerd/containerd/releases/download/v2.1.0/containerd-2.1.0-linux-amd64.tar.gz
tar -xvf containerd-2.1.0-linux-amd64.tar.gz -C kubernetes
rm -rf containerd-2.1.0-linux-amd64.tar.gz
scp kubernetes/containerd root@worker-1:/usr/local/bin
```
