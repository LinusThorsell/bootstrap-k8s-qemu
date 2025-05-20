# Generate SSL certs (do this on the jumpbox)

install `cfssl` (CloudFlare SSL)

```bash
# Get executables
wget https://github.com/cloudflare/cfssl/releases/download/v1.6.5/cfssl_1.6.5_linux_amd64
wget https://github.com/cloudflare/cfssl/releases/download/v1.6.5/cfssljson_1.6.5_linux_amd64

# Make executable
chmod +x cfssl_1.6.5_linux_amd64 cfssljson_1.6.5_linux_amd64

# Install
mv cfssl_1.6.1_linux_amd64 /usr/local/bin/cfssl
mv cfssljson_1.6.1_linux_amd64 /usr/local/bin/cfssljson
```

Create the following folder structure in the home directory:

```bash
.
└── pki
    ├── admin
    ├── api
    ├── ca
    ├── clients
    ├── controller
    ├── front-proxy
    ├── proxy
    ├── scheduler
    ├── service-account
    └── users
```

Create a `ca-config.json` file in the `ca` folder:

```json
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
```

And create a `ca-csr.json` file in the `ca` folder:

```json
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "<2-letter country code>",
      "L": "<city>",
      "O": "Kubernetes",
      "OU": "<organisational unit>",
      "ST": "<state or province>"
    }
  ]
}
```

Generate the CA (Certificate Authority) this will sign the other certificates.

```bash
cfssl gencert -initca pki/ca/ca-csr.json | cfssljson -bare pki/ca/ca
```

You should now have the following filetree:

```bash
.
└── pki
    ├── admin
    ├── api
    ├── ca
    │   ├── ca-config.json
    │   ├── ca-csr.json
    │   ├── ca-key.pem
    │   ├── ca.csr
    │   └── ca.pem
    ├── clients
    ├── controller
    ├── front-proxy
    ├── proxy
    ├── scheduler
    ├── service-account
    └── users
```

Create the admin certificaties (used with kubectl to authenticate and manage the cluster(goes against apiserver)):

Create a `admin-csr.json` file in the `admin` folder:

```json
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "<2-letter country code>",
      "L": "<city>",
      "O": "system:masters",
      "OU": "<organisational unit>",
      "ST": "<state or province>"
    }
  ]
}
```

Generate the admin certificate:

```bash
cfssl gencert \
  -ca=pki/ca/ca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -profile=kubernetes \
  pki/admin/admin-csr.json | cfssljson -bare pki/admin/admin
```

You should now have the following filetree:

```bash
.
└── pki
    ├── admin
    │   ├── admin-csr.json
    │   ├── admin-key.pem
    │   ├── admin.csr
    │   └── admin.pem
    ├── api
    ├── ca
    │   ├── ca-config.json
    │   ├── ca-csr.json
    │   ├── ca-key.pem
    │   ├── ca.csr
    │   └── ca.pem
    ├── clients
    ├── controller
    ├── front-proxy
    ├── proxy
    ├── scheduler
    ├── service-account
    └── users
```

Create the certificate for the workers.

In this demo we will have 2 workers.

Create a `worker-1-csr.json` & a `worker-2-csr.json` file in the `clients` folder:

```json
{
  "CN": "system:node:[VM-NAME]",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "<2-letter country code>",
      "L": "<city>",
      "O": "system:nodes",
      "OU": "<organisational unit>",
      "ST": "<state or province>"
    }
  ]
}
```

Generate the worker certificate:

Get internal ip using `ip addr`

Get external ip using `curl -s -4 https://ifconfig.co/`

```bash
cfssl gencert \
  -ca=pki/ca/ca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -hostname=[VM-NAME],[INTERNAL NETWORK IP],[EXTERNAL NETWORK IP] \
  -profile=kubernetes \
  pki/clients/[VM-NAME]-csr.json | cfssljson -bare pki/clients/[VM-NAME]
```

Now you should have the following filetree:

```bash
.
└── pki
    ├── admin
    │   ├── admin-csr.json
    │   ├── admin-key.pem
    │   ├── admin.csr
    │   └── admin.pem
    ├── api
    ├── ca
    │   ├── ca-config.json
    │   ├── ca-csr.json
    │   ├── ca-key.pem
    │   ├── ca.csr
    │   └── ca.pem
    ├── clients
    │   ├── worker-1-csr.json
    │   ├── worker-1-key.pem
    │   ├── worker-1.csr
    │   ├── worker-1.pem
    │   ├── worker-2-csr.json
    │   ├── worker-2-key.pem
    │   ├── worker-2.csr
    │   └── worker-2.pem
    ├── controller
    ├── front-proxy
    ├── proxy
    ├── scheduler
    ├── service-account
    └── users
```

Certificates for kube-controller-manager

Create a `kube-controller-manager-csr.json` file in the `controller` folder:

```json
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "<2-letter country code>",
      "L": "<city>",
      "O": "system:kube-controller-manager",
      "OU": "<organisational unit>",
      "ST": "<state or province>"
    }
  ]
}
```

Generate the kube-controller-manager certificate:

```bash
cfssl gencert \
  -ca=pki/ca/ca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -profile=kubernetes \
  pki/controller/kube-controller-manager-csr.json | cfssljson -bare pki/controller/kube-controller-manager
```

You should now have the following filetree:

```bash
.
└── pki
    ├── admin
    │   ├── admin-csr.json
    │   ├── admin-key.pem
    │   ├── admin.csr
    │   └── admin.pem
    ├── api
    ├── ca
    │   ├── ca-config.json
    │   ├── ca-csr.json
    │   ├── ca-key.pem
    │   ├── ca.csr
    │   └── ca.pem
    ├── clients
    │   ├── worker-1-csr.json
    │   ├── worker-1-key.pem
    │   ├── worker-1.csr
    │   ├── worker-1.pem
    │   ├── worker-2-csr.json
    │   ├── worker-2-key.pem
    │   ├── worker-2.csr
    │   └── worker-2.pem
    ├── controller
    │   ├── kube-controller-manager-csr.json
    │   ├── kube-controller-manager-key.pem
    │   ├── kube-controller-manager.csr
    │   └── kube-controller-manager.pem
    ├── front-proxy
    ├── proxy
    ├── scheduler
    ├── service-account
    └── users
```

Time to generate the certificates for the kube-proxy:

Create a `kube-proxy-csr.json` file in the `proxy` folder:

```json
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "<2-letter country code>",
      "L": "<city>",
      "O": "system:node-proxier",
      "OU": "<organisational unit>",
      "ST": "<state or province>"
    }
  ]
}
```

Generate the kube-proxy certificate:

```bash
cfssl gencert \
  -ca=pki/ca/ca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -profile=kubernetes \
  pki/proxy/kube-proxy-csr.json | cfssljson -bare pki/proxy/kube-proxy
```

You should now have the following filetree:

```bash
.
└── pki
    ├── admin
    │   ├── admin-csr.json
    │   ├── admin-key.pem
    │   ├── admin.csr
    │   └── admin.pem
    ├── api
    ├── ca
    │   ├── ca-config.json
    │   ├── ca-csr.json
    │   ├── ca-key.pem
    │   ├── ca.csr
    │   └── ca.pem
    ├── clients
    │   ├── worker-1-csr.json
    │   ├── worker-1-key.pem
    │   ├── worker-1.csr
    │   ├── worker-1.pem
    │   ├── worker-2-csr.json
    │   ├── worker-2-key.pem
    │   ├── worker-2.csr
    │   └── worker-2.pem
    ├── controller
    │   ├── kube-controller-manager-csr.json
    │   ├── kube-controller-manager-key.pem
    │   ├── kube-controller-manager.csr
    │   └── kube-controller-manager.pem
    ├── front-proxy
    ├── proxy
    │   ├── kube-proxy-csr.json
    │   ├── kube-proxy-key.pem
    │   ├── kube-proxy.csr
    │   └── kube-proxy.pem
    ├── scheduler
    ├── service-account
    └── users
```

Time to generate the certificates for the kube-scheduler:

Create a `kube-scheduler-csr.json` file in the `scheduler` folder:

```json
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "<2-letter country code>",
      "L": "<city>",
      "O": "system:kube-scheduler",
      "OU": "<organisational unit>",
      "ST": "<state or province>"
    }
  ]
}
```

Generate the kube-scheduler certificate:

```bash
cfssl gencert \
  -ca=pki/ca/ca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -profile=kubernetes \
  pki/scheduler/kube-scheduler-csr.json | cfssljson -bare pki/scheduler/kube-scheduler
```

You should now have the following filetree:

```bash
.
└── pki
    ├── admin
    │   ├── admin-csr.json
    │   ├── admin-key.pem
    │   ├── admin.csr
    │   └── admin.pem
    ├── api
    ├── ca
    │   ├── ca-config.json
    │   ├── ca-csr.json
    │   ├── ca-key.pem
    │   ├── ca.csr
    │   └── ca.pem
    ├── clients
    │   ├── worker-1-csr.json
    │   ├── worker-1-key.pem
    │   ├── worker-1.csr
    │   ├── worker-1.pem
    │   ├── worker-2-csr.json
    │   ├── worker-2-key.pem
    │   ├── worker-2.csr
    │   └── worker-2.pem
    ├── controller
    │   ├── kube-controller-manager-csr.json
    │   ├── kube-controller-manager-key.pem
    │   ├── kube-controller-manager.csr
    │   └── kube-controller-manager.pem
    ├── front-proxy
    ├── proxy
    │   ├── kube-proxy-csr.json
    │   ├── kube-proxy-key.pem
    │   ├── kube-proxy.csr
    │   └── kube-proxy.pem
    ├── scheduler
    │   ├── kube-scheduler-csr.json
    │   ├── kube-scheduler-key.pem
    │   ├── kube-scheduler.csr
    │   └── kube-scheduler.pem
    ├── service-account
    └── users
```

Next up is the front-proxy certificate.

Create a `front-proxy-csr.json` file in the `front-proxy` folder:

```json
{
  "CN": "front-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "<2-letter country code>",
      "L": "<city>",
      "O": "front-proxy",
      "OU": "<organisational unit>",
      "ST": "<state or province>"
    }
  ]
}
```

Generate the front-proxy certificate:

```bash
cfssl gencert \
  -ca=pki/ca/ca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -profile=kubernetes \
  pki/front-proxy/front-proxy-csr.json | cfssljson -bare pki/front-proxy/front-proxy
```

You should now have the following filetree:

```bash
.
└── pki
    ├── admin
    │   ├── admin-csr.json
    │   ├── admin-key.pem
    │   ├── admin.csr
    │   └── admin.pem
    ├── api
    ├── ca
    │   ├── ca-config.json
    │   ├── ca-csr.json
    │   ├── ca-key.pem
    │   ├── ca.csr
    │   └── ca.pem
    ├── clients
    │   ├── worker-1-csr.json
    │   ├── worker-1-key.pem
    │   ├── worker-1.csr
    │   ├── worker-1.pem
    │   ├── worker-2-csr.json
    │   ├── worker-2-key.pem
    │   ├── worker-2.csr
    │   └── worker-2.pem
    ├── controller
    │   ├── kube-controller-manager-csr.json
    │   ├── kube-controller-manager-key.pem
    │   ├── kube-controller-manager.csr
    │   └── kube-controller-manager.pem
    ├── front-proxy
    │   ├── front-proxy-csr.json
    │   ├── front-proxy-key.pem
    │   ├── front-proxy.csr
    │   └── front-proxy.pem
    ├── proxy
    │   ├── kube-proxy-csr.json
    │   ├── kube-proxy-key.pem
    │   ├── kube-proxy.csr
    │   └── kube-proxy.pem
    ├── scheduler
    │   ├── kube-scheduler-csr.json
    │   ├── kube-scheduler-key.pem
    │   ├── kube-scheduler.csr
    │   └── kube-scheduler.pem
    ├── service-account
    └── users
```

Generate the api-server certificate:

Create the `kubernetes-csr.json` file in the `api` folder:

```json
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "<2-letter country code>",
      "L": "<city>",
      "O": "Kubernetes",
      "OU": "<organisational unit>",
      "ST": "<state or province>"
    }
  ]
}
```

Generate the api-server certificate:

Hastname should contain the ip addresses of the master nodes as well as the public ip address of the master node/loadbalancer.

```bash
cfssl gencert \
  -ca=pki/ca/ca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -hostname=[list of controllers],[external ip],127.0.0.1,kubernetes.default \
  -profile=kubernetes \
  pki/api/kubernetes-csr.json | cfssljson -bare pki/api/kubernetes
```

You should now have the following filetree:

```bash
.
└── pki
    ├── admin
    │   ├── admin-csr.json
    │   ├── admin-key.pem
    │   ├── admin.csr
    │   └── admin.pem
    ├── api
    │   ├── kubernetes-csr.json
    │   ├── kubernetes-key.pem
    │   ├── kubernetes.csr
    │   └── kubernetes.pem
    ├── ca
    │   ├── ca-config.json
    │   ├── ca-csr.json
    │   ├── ca-key.pem
    │   ├── ca.csr
    │   └── ca.pem
    ├── clients
    │   ├── worker-1-csr.json
    │   ├── worker-1-key.pem
    │   ├── worker-1.csr
    │   ├── worker-1.pem
    │   ├── worker-2-csr.json
    │   ├── worker-2-key.pem
    │   ├── worker-2.csr
    │   └── worker-2.pem
    ├── controller
    │   ├── kube-controller-manager-csr.json
    │   ├── kube-controller-manager-key.pem
    │   ├── kube-controller-manager.csr
    │   └── kube-controller-manager.pem
    ├── front-proxy
    │   ├── front-proxy-csr.json
    │   ├── front-proxy-key.pem
    │   ├── front-proxy.csr
    │   └── front-proxy.pem
    ├── proxy
    │   ├── kube-proxy-csr.json
    │   ├── kube-proxy-key.pem
    │   ├── kube-proxy.csr
    │   └── kube-proxy.pem
    ├── scheduler
    │   ├── kube-scheduler-csr.json
    │   ├── kube-scheduler-key.pem
    │   ├── kube-scheduler.csr
    │   └── kube-scheduler.pem
    ├── service-account
    └── users
```

Service account time

Create the `service-account-csr.json` file in the `service-account` folder:

```json
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "<2-letter country code>",
      "L": "<city>",
      "O": "Kubernetes",
      "OU": "<organisational unit>",
      "ST": "<state or province>"
    }
  ]
}
```

Generate the service-account certificate:

```bash
cfssl gencert \
  -ca=pki/ca/ca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -profile=kubernetes \
  pki/service-account/service-account-csr.json | cfssljson -bare pki/service-account/service-account
```

You should now have the following filetree:

```bash
.
└── pki
    ├── admin
    │   ├── admin-csr.json
    │   ├── admin-key.pem
    │   ├── admin.csr
    │   └── admin.pem
    ├── api
    │   ├── kubernetes-csr.json
    │   ├── kubernetes-key.pem
    │   ├── kubernetes.csr
    │   └── kubernetes.pem
    ├── ca
    │   ├── ca-config.json
    │   ├── ca-csr.json
    │   ├── ca-key.pem
    │   ├── ca.csr
    │   └── ca.pem
    ├── clients
    │   ├── worker-1-csr.json
    │   ├── worker-1-key.pem
    │   ├── worker-1.csr
    │   ├── worker-1.pem
    │   ├── worker-2-csr.json
    │   ├── worker-2-key.pem
    │   ├── worker-2.csr
    │   └── worker-2.pem
    ├── controller
    │   ├── kube-controller-manager-csr.json
    │   ├── kube-controller-manager-key.pem
    │   ├── kube-controller-manager.csr
    │   └── kube-controller-manager.pem
    ├── front-proxy
    │   ├── front-proxy-csr.json
    │   ├── front-proxy-key.pem
    │   ├── front-proxy.csr
    │   └── front-proxy.pem
    ├── proxy
    │   ├── kube-proxy-csr.json
    │   ├── kube-proxy-key.pem
    │   ├── kube-proxy.csr
    │   └── kube-proxy.pem
    ├── scheduler
    │   ├── kube-scheduler-csr.json
    │   ├── kube-scheduler-key.pem
    │   ├── kube-scheduler.csr
    │   └── kube-scheduler.pem
    ├── service-account
    │   ├── service-account-csr.json
    │   ├── service-account-key.pem
    │   ├── service-account.csr
    │   └── service-account.pem
    └── users
```

All required certificates are now stored in the `pki` folder.

Move the certificates to the machine as follows:

To the worker(s):

```bash
scp -r pki/ca/ca.pem root@worker-X:/etc/kubernetes/pki/ca.pem
scp -r pki/clients/worker-X.pem root@worker-X:/etc/kubernetes/pki/worker.pem
scp -r pki/clients/worker-X-key.pem root@worker-X:/etc/kubernetes/pki/worker-key.pem
```

To the controller(s):

```bash
scp -r pki/ca/ca.pem root@control-1:/etc/kubernetes/pki/ca.pem
scp -r pki/ca/ca-key.pem root@control-1:/etc/kubernetes/pki/ca-key.pem
# TODO rename to correct, for ex: kubernetes should be apiserver i think.
scp -r pki/api/kubernetes.pem root@control-1:/etc/kubernetes/pki/kubernetes.pem
scp -r pki/api/kubernetes-key.pem root@control-1:/etc/kubernetes/pki/kubernetes-key.pem
scp -r pki/service-account/service-account.pem root@control-1:/etc/kubernetes/pki/service-account.pem
scp -r pki/service-account/service-account-key.pem root@control-1:/etc/kubernetes/pki/service-account-key.pem
scp -r pki/front-proxy/front-proxy.pem root@control-1:/etc/kubernetes/pki/front-proxy.pem
scp -r pki/front-proxy/front-proxy-key.pem root@control-1:/etc/kubernetes/pki/front-proxy-key.pem
```
