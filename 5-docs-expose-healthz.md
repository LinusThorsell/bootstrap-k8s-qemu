# To be able to expose healthchecks for loadbalancer nodes we use nginx.

Onm the control node(s) run:

`apt-get install -y nginx`

```bash
rc-service nginx start
```

create the file /etc/nginx/http.d/kubernetes.conf:

```bash
server {
  listen      80;
  server_name kubernetes.default.svc.cluster.local; # This is important for Nginx to match the incoming request

  location = /healthz {
     proxy_pass                    https://127.0.0.1:6443/healthz;
     proxy_ssl_trusted_certificate /etc/kubernetes/pki/ca.pem;
  }
}
```

FIXME: healthz is deprecated use readyz

restart nginx:

```bash
rc-service nginx restart
```

try it from within the control node:

```bash
# curl -H "Host: kubernetes.default.svc.cluster.local" -i http://127.0.0.1/healthz
HTTP/1.1 200 OK
Server: nginx
Date: Tue, 20 May 2025 12:39:50 GMT
Content-Type: text/plain; charset=utf-8
Content-Length: 2
Connection: keep-alive
Audit-Id: 0d32ab5f-8c2f-44a6-a517-40a951082d57
Cache-Control: no-cache, private
X-Content-Type-Options: nosniff
X-Kubernetes-Pf-Flowschema-Uid: ba2b0c47-8827-4a28-a426-fd89a832c9a4
X-Kubernetes-Pf-Prioritylevel-Uid: 9954627c-a0ef-4f2c-b2be-896ebe0f5389
```

Try it from the jumpbox:

```bash
curl -H "Host: kubernetes.default.svc.cluster.local" -i http://[control-node-ip]/healthz?verbose
```

you should get the same response
