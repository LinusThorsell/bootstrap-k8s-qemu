# LoadBalancing.

Now we need to set up a way to access our cluster remotely, we will do this by setting up a load balancer (in this case HAProxy) on the jumpbox (generally you would place this on a highly available setup with failover ip as well.)

Goal of chapter is to expose both controlling parts like apiserver to the nodes and the healthcheck endpoint to the remote.

## Installing HAProxy on the jumpbox

```bash
apk add haproxy
```

Edit the `/etc/haproxy/haproxy.cfg` file to contain:

FIXME: add certs for https for healtz endpoint is porbably a good idea.
```bash
global
        log /dev/log    local0
        chroot /var/lib/haproxy
        stats timeout 30s
        user haproxy
        group haproxy
        daemon

defaults
        log     global
        mode    http
        option  httplog
        option  dontlognull
        timeout connect 5000ms
        timeout client 50000ms
        timeout server 50000ms

frontend apiservers
        bind *:80
        default_backend apiservers

backend apiservers
        mode http
        balance roundrobin
        option forwardfor
        http-request set-header Host kubernetes.default.svc.cluster.local
        default-server inter 10s fall 2
        server control-1 192.168.122.11:80 check

frontend kube-api
        bind *:6443
        mode tcp
        option tcplog
        default_backend kube-api

backend kube-api
        mode tcp
        option ssl-hello-chk
        option log-health-checks
        default-server inter 10s fall 2
        server k8s-controller-0 192.168.122.11:6443 check
```

restart the service

```bash
rc-service haproxy restart
```

try the healthcheck from the jumpbox localhost:

`jumpbox:~# curl http://localhost:80/healthz`

change the contents of `configs/admin/admin.kubeconfig` to have server: localhost instead of control-1

test the changes using:

`kubectl version --kubeconfig configs/admin/admin.kubeconfig`

if it works, make kubectl always use the loadbalancer on the jumpbox

`jumpbox:~# cp configs/admin/admin.kubeconfig ~/.kube/config`

try that it works

`kubectl version`

You should also be able to communicate using CA cert and curl like this:

```bash
$ jumpbox:~# curl --cacert pki/ca/ca.pem https://127.0.0.1:6443/version
{
  "major": "1",
  "minor": "33",
  "emulationMajor": "1",
  "emulationMinor": "33",
  "minCompatibilityMajor": "1",
  "minCompatibilityMinor": "32",
  "gitVersion": "v1.33.1",
  "gitCommit": "8adc0f041b8e7ad1d30e29cc59c6ae7a15e19828",
  "gitTreeState": "clean",
  "buildDate": "2025-05-15T08:19:08Z",
  "goVersion": "go1.24.2",
  "compiler": "gc",
  "platform": "linux/amd64"
}
```

if this works the loadbalancer is set up correctly.
