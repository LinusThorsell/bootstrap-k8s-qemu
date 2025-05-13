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
9. APK Mirror: `1` & `1`
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

## Setting up k3s on the VM


