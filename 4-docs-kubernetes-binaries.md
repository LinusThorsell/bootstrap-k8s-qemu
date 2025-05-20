# installing the binaries for kubernetes

Download binaries (on jumpbox):

mkdir kubernetes

```bash
wget -P kubernetes https://dl.k8s.io/v1.33.1/bin/linux/amd64/kube-apiserver
wget -P kubernetes https://dl.k8s.io/v1.33.1/bin/linux/amd64/kube-controller-manager
wget -P kubernetes https://dl.k8s.io/v1.33.1/bin/linux/amd64/kube-scheduler
wget -P kubernetes https://dl.k8s.io/v1.33.1/bin/linux/amd64/kubectl
```

Move to the control node(s):

```bash
scp kubernetes/* root@control-1:/usr/local/bin/
```

On the control node(s):

```bash
chmod +x /usr/local/bin/kubectl 
chmod +x /usr/local/bin/kube-apiserver 
chmod +x /usr/local/bin/kube-controller-manager 
chmod +x /usr/local/bin/kube-scheduler 
```

Try running kubectl to make sure it is installed.

Create API server `configs/api/audit-policy.yaml`

```yaml
apiVersion: audit.k8s.io/v1 # This is required.
kind: Policy
# Don't generate audit events for all requests in RequestReceived stage.
omitStages:
  - "RequestReceived"
rules:
  # Log pod changes at RequestResponse level
  - level: RequestResponse
    resources:
    - group: ""
      # Resource "pods" doesn't match requests to any subresource of pods,
      # which is consistent with the RBAC policy.
      resources: ["pods"]
  # Log "pods/log", "pods/status" at Metadata level
  - level: Metadata
    resources:
    - group: ""
      resources: ["pods/log", "pods/status"]

  # Don't log requests to a configmap called "controller-leader"
  - level: None
    resources:
    - group: ""
      resources: ["configmaps"]
      resourceNames: ["controller-leader"]

  # Don't log watch requests by the "system:kube-proxy" on endpoints or services
  - level: None
    users: ["system:kube-proxy"]
    verbs: ["watch"]
    resources:
    - group: "" # core API group
      resources: ["endpoints", "services"]

  # Don't log authenticated requests to certain non-resource URL paths.
  - level: None
    userGroups: ["system:authenticated"]
    nonResourceURLs:
    - "/api*" # Wildcard matching.
    - "/version"

  # Log the request body of configmap changes in kube-system.
  - level: Request
    resources:
    - group: "" # core API group
      resources: ["configmaps"]
    # This rule only applies to resources in the "kube-system" namespace.
    # The empty string "" can be used to select non-namespaced resources.
    namespaces: ["kube-system"]

  # Log configmap and secret changes in all other namespaces at the Metadata level.
  - level: Metadata
    resources:
    - group: "" # core API group
      resources: ["secrets", "configmaps"]

  # Log all other resources in core and extensions at the Request level.
  - level: Request
    resources:
    - group: "" # core API group
    - group: "extensions" # Version of group should NOT be included.

  # A catch-all rule to log all other requests at the Metadata level.
  - level: Metadata
    # Long-running requests like watches that fall under this rule will not
    # generate an audit event in RequestReceived.
    omitStages:
      - "RequestReceived"
```

Move audit-policy to the control node(s):

```bash
scp configs/api/audit-policy.yaml root@control-1:/etc/kubernetes/audit-policy.yaml
```

# setting upp kube-apiserver on controllers

## Create service file

create the service file `kubernetes/kube-apiserver.service`:

```bash
#!/sbin/openrc-run

name=kube-apiserver
description="kube-apiserver"
command=/usr/local/bin/kube-apiserver

depend() {
    need net
    after firewall
}

command_args="
  --advertise-address=${INTERNAL_IP} \
  --allow-privileged=true \
  --audit-policy-file=${AUDIT_POLICY} \
  --audit-log-maxage=30 \
  --audit-log-maxbackup=3 \
  --audit-log-maxsize=100 \
  --audit-log-path=/var/log/audit.log \
  --authorization-mode=Node,RBAC \
  --bind-address=0.0.0.0 \
  --client-ca-file=${CA_FILE} \
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \
  --etcd-cafile=${CA_FILE} \
  --etcd-certfile=${KUBERNETES_PEM_FILE} \
  --etcd-keyfile=${KUBERNETES_KEY_FILE} \
  --etcd-servers=${ETCD_SERVERS} \
  --event-ttl=1h \
  --encryption-provider-config=${ENCRYPTION_CONFIG} \
  --kubelet-certificate-authority=${CA_FILE} \
  --kubelet-client-certificate=${KUBERNETES_PEM_FILE} \
  --kubelet-client-key=${KUBERNETES_KEY_FILE} \
  --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname \
  --proxy-client-cert-file=${FRONT_PROXY_PEM_FILE} \
  --proxy-client-key-file=${FRONT_PROXY_KEY_FILE} \
  --requestheader-allowed-names=front-proxy-client \
  --requestheader-client-ca-file=${CA_FILE} \
  --requestheader-extra-headers-prefix=X-Remote-Extra- \
  --requestheader-group-headers=X-Remote-Group \
  --requestheader-username-headers=X-Remote-User \
  --runtime-config='api/all=true' \
  --secure-port=6443 \
  --service-account-issuer=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
  --service-account-key-file=${SERVICE_ACCOUNT_PEM_FILE} \
  --service-account-signing-key-file=${SERVICE_ACCOUNT_KEY_FILE} \
  --service-cluster-ip-range=10.32.0.0/24 \
  --service-node-port-range=30000-32767 \
  --tls-cert-file=${KUBERNETES_PEM_FILE} \
  --tls-private-key-file=${KUBERNETES_KEY_FILE} \
  --v=2
"

command_background=true
pidfile="/run/${RC_SVCNAME}.pid"
```

create the configuration file `kubernetes/kube-apiserver.conf`:

```bash
# Kubernetes apiserver configuration

# General
INTERNAL_IP="192.168.122.11" # IP of control node
ETCD_SERVERS="https://192.168.122.11:2379" # add more here as csv for multi etcd and HA
KUBERNETES_PUBLIC_ADDRESS="127.0.0.1"

# Configs
AUDIT_POLICY="/etc/kubernetes/audit-policy.yaml"
ENCRYPTION_CONFIG="/etc/kubernetes/encryption-config.yaml"

# Certificates
CA_FILE="/etc/kubernetes/pki/ca.pem"
KUBERNETES_KEY_FILE="/etc/kubernetes/pki/kubernetes-key.pem"
KUBERNETES_PEM_FILE="/etc/kubernetes/pki/kubernetes.pem"
SERVICE_ACCOUNT_KEY_FILE="/etc/kubernetes/pki/service-account-key.pem"
SERVICE_ACCOUNT_PEM_FILE="/etc/kubernetes/pki/service-account.pem"
FRONT_PROXY_KEY_FILE="/etc/kubernetes/pki/front-proxy-key.pem"
FRONT_PROXY_PEM_FILE="/etc/kubernetes/pki/front-proxy.pem"
```

Move files onto the control node(s):

```bash
scp kubernetes/kube-apiserver.service root@control-1:/etc/init.d/kube-apiserver
scp kubernetes/kube-apiserver.conf root@control-1:/etc/conf.d/kube-apiserver
```

On the control node(s) run `chmod +x /etc/init.d/kube-apiserver`, `rc-update add kube-apiserver` and `rc-service kube-apiserver start`

Check installation status:

```bash
# FIXME: write test command here
```

## Setting up kube-controller-manager

create the service file `kubernetes/kube-controller-manager.service`:

```bash
#!/sbin/openrc-run

name=kube-controller-manager
description="kube-controller-manager"
command=/usr/local/bin/kube-controller-manager

depend() {
    need net
    after firewall
}

command_args="
  --allocate-node-cidrs=true \
  --bind-address=0.0.0.0 \
  --cluster-cidr=10.200.0.0/16 \
  --cluster-name=LTNetes \
  --cluster-signing-cert-file=${CA_FILE} \
  --cluster-signing-key-file=${CA_KEY} \
  --kubeconfig=${CONTROLLER_MANAGER_CONF} \
  --leader-elect=true \
  --root-ca-file=${CA_FILE} \
  --service-account-private-key-file=${SERVICE_ACCOUNT_KEY_FILE} \
  --service-cluster-ip-range=10.32.0.0/24 \
  --use-service-account-credentials=true \
  --v=2
"

command_background=true
pidfile="/run/${RC_SVCNAME}.pid"
```

create the configuration file `kubernetes/kube-controller-manager.conf`:

```bash
# Kubernetes controller-manager configuration

# General
CONTROLLER_MANAGER_CONF="/etc/kubernetes/controller-manager.conf"

# Certificates
CA_FILE="/etc/kubernetes/pki/ca.pem"
CA_KEY="/etc/kubernetes/pki/ca-key.pem"
SERVICE_ACCOUNT_KEY_FILE="/etc/kubernetes/pki/service-account-key.pem"
```

Move files onto the control node(s):

```bash
scp kubernetes/kube-controller-manager.service root@control-1:/etc/init.d/kube-controller-manager
scp kubernetes/kube-controller-manager.conf root@control-1:/etc/conf.d/kube-controller-manager
```

On the control node(s) run `chmod +x /etc/init.d/kube-controller-manager`, `rc-update add kube-controller-manager` and `rc-service kube-controller-manager start`

## Setting up kube-scheduler

create the service config file  `configs/scheduler/kube-scheduler.yaml`:

```yaml
apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/etc/kubernetes/scheduler.conf"
leaderElection:
  leaderElect: true
```

Move file onto the control node(s):

```bash
ssh root@control-1 'mkdir /etc/kubernetes/config'
scp configs/scheduler/kube-scheduler.yaml root@control-1:/etc/kubernetes/config/scheduler.yaml
```

create the service file `kubernetes/kube-scheduler.service`:

```bash
#!/sbin/openrc-run

name=kube-scheduler
description="kube-scheduler"
command=/usr/local/bin/kube-scheduler

depend() {
    need net
    after firewall
}

command_args="
  --config=${SCHEDULER_CONF} \
  --v=2
"

command_background=true
pidfile="/run/${RC_SVCNAME}.pid"
```

create the configuration file `kubernetes/kube-scheduler.conf`:

```bash
# Kubernetes scheduler configuration

# General
SCHEDULER_CONF="/etc/kubernetes/config/scheduler.yaml"
```

Move files onto the control node(s):

```bash
scp kubernetes/kube-scheduler.service root@control-1:/etc/init.d/kube-scheduler
scp kubernetes/kube-scheduler.conf root@control-1:/etc/conf.d/kube-scheduler
```

On the control node(s) run `chmod +x /etc/init.d/kube-scheduler`, `rc-update add kube-scheduler` and `rc-service kube-scheduler start`

Verify that everything is working from the jumpbox:

```bash
kubectl get componentstatuses --kubeconfig configs/admin/admin.kubeconfig
```

You should get:

```bash
# curl -k https://[control-1]:6443/livez?verbose
[+]ping ok
[+]log ok
[+]etcd ok
[+]poststarthook/start-apiserver-admission-initializer ok
[+]poststarthook/generic-apiserver-start-informers ok
[+]poststarthook/priority-and-fairness-config-consumer ok
[+]poststarthook/priority-and-fairness-filter ok
[+]poststarthook/storage-object-count-tracker-hook ok
[+]poststarthook/start-apiextensions-informers ok
[+]poststarthook/start-apiextensions-controllers ok
[+]poststarthook/crd-informer-synced ok
[+]poststarthook/start-system-namespaces-controller ok
[+]poststarthook/start-cluster-authentication-info-controller ok
[+]poststarthook/start-kube-apiserver-identity-lease-controller ok
[+]poststarthook/start-kube-apiserver-identity-lease-garbage-collector ok
[+]poststarthook/start-legacy-token-tracking-controller ok
[+]poststarthook/start-service-ip-repair-controllers ok
[+]poststarthook/rbac/bootstrap-roles ok
[+]poststarthook/scheduling/bootstrap-system-priority-classes ok
[+]poststarthook/priority-and-fairness-config-producer ok
[+]poststarthook/bootstrap-controller ok
[+]poststarthook/start-kubernetes-service-cidr-controller ok
[+]poststarthook/aggregator-reload-proxy-client-cert ok
[+]poststarthook/start-kube-aggregator-informers ok
[+]poststarthook/apiservice-status-local-available-controller ok
[+]poststarthook/apiservice-status-remote-available-controller ok
[+]poststarthook/apiservice-registration-controller ok
[+]poststarthook/apiservice-discovery-controller ok
[+]poststarthook/kube-apiserver-autoregistration ok
[+]autoregister-completion ok
[+]poststarthook/apiservice-openapi-controller ok
[+]poststarthook/apiservice-openapiv3-controller ok
livez check passed

# curl -k https://[control-1]:6443/readyz?verbose
[+]ping ok
[+]log ok
[+]etcd ok
[+]etcd-readiness ok
[+]informer-sync ok
[+]poststarthook/start-apiserver-admission-initializer ok
[+]poststarthook/generic-apiserver-start-informers ok
[+]poststarthook/priority-and-fairness-config-consumer ok
[+]poststarthook/priority-and-fairness-filter ok
[+]poststarthook/storage-object-count-tracker-hook ok
[+]poststarthook/start-apiextensions-informers ok
[+]poststarthook/start-apiextensions-controllers ok
[+]poststarthook/crd-informer-synced ok
[+]poststarthook/start-system-namespaces-controller ok
[+]poststarthook/start-cluster-authentication-info-controller ok
[+]poststarthook/start-kube-apiserver-identity-lease-controller ok
[+]poststarthook/start-kube-apiserver-identity-lease-garbage-collector ok
[+]poststarthook/start-legacy-token-tracking-controller ok
[+]poststarthook/start-service-ip-repair-controllers ok
[+]poststarthook/rbac/bootstrap-roles ok
[+]poststarthook/scheduling/bootstrap-system-priority-classes ok
[+]poststarthook/priority-and-fairness-config-producer ok
[+]poststarthook/bootstrap-controller ok
[+]poststarthook/start-kubernetes-service-cidr-controller ok
[+]poststarthook/aggregator-reload-proxy-client-cert ok
[+]poststarthook/start-kube-aggregator-informers ok
[+]poststarthook/apiservice-status-local-available-controller ok
[+]poststarthook/apiservice-status-remote-available-controller ok
[+]poststarthook/apiservice-registration-controller ok
[+]poststarthook/apiservice-discovery-controller ok
[+]poststarthook/kube-apiserver-autoregistration ok
[+]autoregister-completion ok
[+]poststarthook/apiservice-openapi-controller ok
[+]poststarthook/apiservice-openapiv3-controller ok
[+]shutdown ok
readyz check passed
```
