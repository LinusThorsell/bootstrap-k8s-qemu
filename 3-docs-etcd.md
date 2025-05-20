# setting upp etcd on controllers

## install etcd

mkdir etcd

```bash
# FIXME: make this happen in the etcd folder
wget https://github.com/etcd-io/etcd/releases/download/v3.6.0/etcd-v3.6.0-linux-amd64.tar.gz
tar xzvf etcd-v3.6.0-linux-amd64.tar.gz
scp etcd-v3.6.0-linux-amd64/etcd* root@control-1:/usr/local/bin/
```

create the service file `etcd/etcd.service`:

```bash
#!/sbin/openrc-run

name=etcd
description="etcd key-value store"
command=/usr/local/bin/etcd

depend() {
    need net
    after firewall
}

start_pre() {
    checkpath --directory --mode 0755 /var/lib/etcd
}

command_args="
  --name ${ETCD_NAME} \
  --data-dir=/var/lib/etcd \
  --listen-peer-urls https://${INTERNAL_IP}:2380 \
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \
  --initial-cluster ${INITIAL_CLUSTER} \
  --initial-cluster-state new \
  --initial-cluster-token etcd-cluster-0 \
  --advertise-client-urls https://${INTERNAL_IP}:2379 \
  --cert-file=${CERT_FILE} \
  --key-file=${KEY_FILE} \
  --client-cert-auth \
  --trusted-ca-file=${CA_FILE} \
  --peer-cert-file=${CERT_FILE} \
  --peer-key-file=${KEY_FILE} \
  --peer-client-cert-auth \
  --peer-trusted-ca-file=${CA_FILE}
"

command_background=true
pidfile="/run/${RC_SVCNAME}.pid"
```

create the configuration file `etcd/etcd.conf`:

```bash
# etcd configuration
ETCD_NAME="control-1"
INTERNAL_IP="192.168.122.11" # IP of control node
INITIAL_CLUSTER="control-1=https://192.168.122.11:2380" # add more here as csv for multi etcd and HA

CERT_FILE="/etc/kubernetes/pki/kubernetes.pem"
KEY_FILE="/etc/kubernetes/pki/kubernetes-key.pem"
CA_FILE="/etc/kubernetes/pki/ca.pem"
```

Move files onto the control node(s):

```bash
scp etcd/etcd.service root@control-1:/etc/init.d/etcd
scp etcd/etcd.conf root@control-1:/etc/conf.d/etcd
```

On the control node(s) run `chmod +x /etc/init.d/etcd`, `rc-update add etcd` and `rc-service etcd start`

Check installation status:

```bash
etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/ca.pem \
  --cert=/etc/kubernetes/pki/kubernetes.pem \
  --key=/etc/kubernetes/pki/kubernetes-key.pem
```

Make sure all etcd members are started.
