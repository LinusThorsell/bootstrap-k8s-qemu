# Let's allow communication between the kube-apiserver and the kubelet

Create the file `apply-kubernetes/rbac-clusterrole.yaml`

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
```

Apply the ClusterRole:

FIXME: --kubeconfig is maybe not needed here after the lb step. investigate.
```bash
kubectl apply --kubeconfig configs/admin/admin.kubeconfig -f apply-kubernetes/rbac-clusterrole.yaml
```

Create the file `apply-kubernetes/rbac-clusterrolebinding.yaml`

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
```

```bash
kubectl apply --kubeconfig configs/admin/admin.kubeconfig -f apply-kubernetes/rbac-clusterrolebinding.yaml
```
