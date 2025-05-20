time for some configs woop

on jumpbox

`mkdir configs`

# worker 1

kubectl config set-cluster LTNetes\
    --certificate-authority=pki/ca/ca.pem \
    --embed-certs=true \
    --server=https://control-1:6443 \
    --kubeconfig=configs/clients/worker-1.kubeconfig

kubectl config set-credentials system:node:worker-1 \
    --client-certificate=pki/clients/worker-1.pem \
    --client-key=pki/clients/worker-1-key.pem \
    --embed-certs=true \
    --kubeconfig=configs/clients/worker-1.kubeconfig

kubectl config set-context default \
    --cluster=LTNetes \
    --user=system:node:worker-1 \
    --kubeconfig=configs/clients/worker-1.kubeconfig

kubectl config use-context default --kubeconfig=configs/clients/worker-1.kubeconfig

# worker 2

kubectl config set-cluster LTNetes\
    --certificate-authority=pki/ca/ca.pem \
    --embed-certs=true \
    --server=https://control-1:6443 \
    --kubeconfig=configs/clients/worker-2.kubeconfig

kubectl config set-credentials system:node:worker-2 \
    --client-certificate=pki/clients/worker-2.pem \
    --client-key=pki/clients/worker-2-key.pem \
    --embed-certs=true \
    --kubeconfig=configs/clients/worker-2.kubeconfig

kubectl config set-context default \
    --cluster=LTNetes \
    --user=system:node:worker-2 \
    --kubeconfig=configs/clients/worker-2.kubeconfig

kubectl config use-context default --kubeconfig=configs/clients/worker-2.kubeconfig

# kube-proxy

kubectl config set-cluster LTNetes \
  --certificate-authority=pki/ca/ca.pem \
  --embed-certs=true \
  --server=https://control-1:6443 \
  --kubeconfig=configs/proxy/kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
  --client-certificate=pki/proxy/kube-proxy.pem \
  --client-key=pki/proxy/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=configs/proxy/kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=LTNetes \
  --user=system:kube-proxy \
  --kubeconfig=configs/proxy/kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=configs/proxy/kube-proxy.kubeconfig

# kube-controller-manager

kubectl config set-cluster LTNetes \
  --certificate-authority=pki/ca/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=configs/controller/kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=pki/controller/kube-controller-manager.pem \
  --client-key=pki/controller/kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=configs/controller/kube-controller-manager.kubeconfig

kubectl config set-context default \
  --cluster=LTNetes \
  --user=system:kube-controller-manager \
  --kubeconfig=configs/controller/kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=configs/controller/kube-controller-manager.kubeconfig

# kube-scheduler

kubectl config set-cluster LTNetes \
  --certificate-authority=pki/ca/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=configs/scheduler/kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=pki/scheduler/kube-scheduler.pem \
  --client-key=pki/scheduler/kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=configs/scheduler/kube-scheduler.kubeconfig

kubectl config set-context default \
  --cluster=LTNetes \
  --user=system:kube-scheduler \
  --kubeconfig=configs/scheduler/kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=configs/scheduler/kube-scheduler.kubeconfig

# admin user config

kubectl config set-cluster LTNetes \
  --certificate-authority=pki/ca/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=configs/admin/admin.kubeconfig

kubectl config set-credentials admin \
  --client-certificate=pki/admin/admin.pem \
  --client-key=pki/admin/admin-key.pem \
  --embed-certs=true \
  --kubeconfig=configs/admin/admin.kubeconfig

kubectl config set-context default \
  --cluster=LTNetes \
  --user=admin \
  --kubeconfig=configs/admin/admin.kubeconfig

kubectl config use-context default --kubeconfig=configs/admin/admin.kubeconfig

Move the files:

```bash
# note that the things are renamed to kubelet conf here FIXME: migbt be incorrect
scp configs/clients/worker-1.kubeconfig root@worker-1:/etc/kubernetes/kubelet.conf
scp configs/clients/worker-2.kubeconfig root@worker-2:/etc/kubernetes/kubelet.conf
scp configs/proxy/kube-proxy.kubeconfig root@worker-1:/etc/kubernetes/kube-proxy.conf
scp configs/proxy/kube-proxy.kubeconfig root@worker-2:/etc/kubernetes/kube-proxy.conf

scp configs/admin/admin.kubeconfig root@control-1:/etc/kubernetes/admin.conf
scp configs/controller/kube-controller-manager.kubeconfig root@control-1:/etc/kubernetes/controller-manager.conf
scp configs/scheduler/kube-scheduler.kubeconfig root@control-1:/etc/kubernetes/scheduler.conf
```

# encryption keys

`mkdir data-encryption`

```bash
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
cat > data-encryption/encryption-config.yaml <<EOF
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
    - aescbc:
        keys:
        - name: key1
          secret: ${ENCRYPTION_KEY}
    - identity: {}
EOF
```

