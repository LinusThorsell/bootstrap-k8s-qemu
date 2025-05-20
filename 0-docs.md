# Learning k3s using virtualized environment in QEMU.

## Install QEMU & VM

Install QEMU:

`apt-get install qemu-system`

Create a disk image:

`qemu-img create -f qcow2 <name>.qcow2 <size>G`

Launch image for manual setup:

`./scripts/start_node_setup.sh -i <name>.qcow2 -s <iso> -m <memory in mb>`

Log in using `root` no password required.

Run `setup-alpine` and follow the instructions install as follows:
1. Hostname: `node-<x>`
2. Interface: `eth0` (or whatever is default)
3. IP: `dhcp`
4. Manual network configuration: `n`
5. Password: `admin` (change for production)
6. Timezone: `Europe/Stockholm`
7: Proxy: `none`
8. NTP: `chrony`
9. APK Mirror: `f`
10. User: `no`
11. Which SSH server: `openssh`
12. Allow root login: `yes`
13. SSH key: `none` (will set up later)
14. Select disk: `sda`
15. Installation type: `sys`
16. Erase disk(s) and continues: `y`
17. Close VM using `CTRL-A X`

Execute the start script:

`./scripts/start_node.sh -i <name>.qcow2 -p <ssh port> -m <memory in mb>`

Apply SSH key:

`ssh-copy-id -p <port> root@localhost`

SSH using SSH key:

`ssh -p <port> root@localhost`

The VM is now successfully set up.

Repeat this for the following nodes: jumpbox, control-1, worker-1 & worker-2.

## Install VMs in libvirt:

Create libvirt `default` network if it does not exist yet. (list it with `sudo virsh net-list` make sure its started and active.)

Install disk image to libvirt:

```bash
sudo virt-install \
  --name=[name-of-vm] \
  --memory=2048 \
  --vcpus=2 \
  --disk drives/[name-of-vm].qcow2,format=qcow2 \
  --import \
  --os-variant=generic \
  --network network=default \
  --noautoconsole
```

Repeat above for all VMs.

### Give all VMs static unique IPs.

Get MAC address for each VM:

```bash
sudo virsh dumpxml [name-of-vm] | grep "mac address"
```

Add the mac address to the `default` network like this:

```bash
sudo EDITOR=nvim virsh net-edit default
```

Add the following line:

```bash
<network connections='4'>
  <name>default</name>
  <uuid>1ac4b291-a2e2-4188-9b02-0bf09d0bce79</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:d2:b1:3a'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
      <host mac='52:54:00:2a:28:22' name='jumpbox' ip='192.168.122.10'/> <-- THIS fill name, mac and wanted IP.
      <host ... next host .../>
      etc...
    </dhcp>
  </ip>
</network>
```

Repeat for all VMs then reboot host machine. Optionally edit `/etc/hosts` with VM names as aliases to their IPs.

On AlpineOS you may have to do `rc-service networking restart` to make the network settings take effect.

Now every VM has a static IP and is on the same network as the others.

## Sanity check / example conf:

```bash
❯ sudo virsh list
 Id   Name        State
---------------------------
 1    control-1   running
 2    jumpbox     running
 3    worker-1    running
 4    worker-2    running
```

```bash
❯ sudo virsh net-dumpxml default
<network connections='4'>
  <name>default</name>
  <uuid>1ac4b291-a2e2-4188-9b02-0bf09d0bce79</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:d2:b1:3a'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
      <host mac='52:54:00:2a:28:22' name='jumpbox' ip='192.168.122.10'/>
      <host mac='52:54:00:3c:ae:87' name='control-1' ip='192.168.122.11'/>
      <host mac='52:54:00:88:ec:3a' name='worker-1' ip='192.168.122.12'/>
      <host mac='52:54:00:67:71:71' name='worker-2' ip='192.168.122.13'/>
    </dhcp>
  </ip>
</network>
```

```bash
❯ cat /etc/hosts
127.0.0.1 localhost
::1 localhost

192.168.122.10 jumpbox
192.168.122.11 control-1
192.168.122.12 worker-1
192.168.122.13 worker-2
```

temp list
```
https://dl.k8s.io/v1.32.3/bin/linux/amd64/kubectl
https://dl.k8s.io/v1.32.3/bin/linux/amd64/kube-apiserver
https://dl.k8s.io/v1.32.3/bin/linux/amd64/kube-controller-manager
https://dl.k8s.io/v1.32.3/bin/linux/amd64/kube-scheduler
https://dl.k8s.io/v1.32.3/bin/linux/amd64/kube-proxy
https://dl.k8s.io/v1.32.3/bin/linux/amd64/kubelet
https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.32.0/crictl-v1.32.0-linux-amd64.tar.gz
https://github.com/opencontainers/runc/releases/download/v1.3.0-rc.1/runc.amd64
https://github.com/containernetworking/plugins/releases/download/v1.6.2/cni-plugins-linux-amd64-v1.6.2.tgz
https://github.com/containerd/containerd/releases/download/v2.1.0-beta.0/containerd-2.1.0-beta.0-linux-amd64.tar.gz
https://github.com/etcd-io/etcd/releases/download/v3.6.0-rc.3/etcd-v3.6.0-rc.3-linux-amd64.tar.gz
```

## Jumpbox setup

Download kubectl:

`wget https://dl.k8s.io/v1.33.0/bin/linux/amd64/kubectl`

Make executable:

`chmod +x kubectl`

Move to `/usr/local/bin`:

`sudo mv kubectl /usr/local/bin`

Make sure it is installed correctly:

`kubectl version --client`
