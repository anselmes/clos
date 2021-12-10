#!/bin/bash

# vars
export CLOS_DISK_UUID=""

## mounts
cat <<-eof | sudo tee /etc/systemd/system/var-cloudos.automount
[Unit]
Description=CloudOS (/var/cloudos)
ConditionPathExists=/var/cloudos

[Automount]
Where=/var/cloudos
TimeoutIdleSec=10

[Install]
WantedBy=multi-user.target
eof
cat <<-eof | sudo tee /etc/systemd/system/var-cloudos.mount
[Unit]
Description=CloudOS (/var/cloudos)
DefaultDependencies=no
Conflicts=umount.target
Before=local-fs.target umount.target
After=swap.target

[Mount]
What=/dev/disk/by-uuid/${CLOS_DISK_UUID}
Where=/var/cloudos
Type=xfs
Options=defaults

[Install]
WantedBy=multi-user.target
eof

sudo systemctl enable var-cloudos.automount
sudo systemctl start var-cloudos.automount

# network
cat <<-eof > /etc/netplan/00-installer-config.yaml
# This is the network config written by 'cloudos'
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
      set-name: eth0
      match:
        macaddress: ${IF_MAC_ADDR}
eof

# landscape
landscape-config \
  --computer-title ${NAME} \
  --account-name standalone  \
  --url ${LANDSCAPE_URL} \
  --ping-url ${LANDSCAPE_PING_URL} \
  -p ${REGISTRATION_KEY}

# register
ua attach ${TOKEN}

ua enable cis
ua enable fips
ua enable fips-updates

ua status

## kubernetes
sudo kubeadm init --image-repository public.ecr.aws/eks-distro/kubernetes --kubernetes-version v1.19.8-eks-1-19-4

# addon
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=v1.19.8-eks-1-19-4"

# taints
kubectl taint nodes --all node-role.kubernetes.io/master-

# kubevip
kubectl get configmap kube-proxy -n kube-system -o yaml \
| sed -e "s/strictARP: false/strictARP: true/" \
| kubectl apply -f - -n kube-system

kubectl create configmap --namespace kube-system kubevip --from-literal cidr-global=${CIDR}

kubectl apply -f https://kube-vip.io/manifests/controller.yaml
kubectl apply -f https://kube-vip.io/manifests/rbac.yaml

alias kube-vip="docker run --network host --rm plndr/kube-vip:v0.3.5"
kube-vip manifest daemonset --services --inCluster --arp --interface ${VIP_INTERFACE} | kubectl apply -f -

# TODO: operators rbac
kubectl create clusterrolebinding --clusterrole=cluster-admin --group system:serviceaccounts:operators operator-admin

# olm
curl -sL https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.19.1/install.sh | bash -s v0.19.1

# demoapp (optional)
kubectl apply -f https://anywhere.eks.amazonaws.com/manifests/hello-eks-a.yaml
kubectl expose deployment hello-eks-a --port=80 --type=LoadBalancer --name=hello-eks-a-lb

# add node
docker pull public.ecr.aws/eks-distro/kubernetes/pause:v1.19.8-eks-1-19-4;\
docker tag public.ecr.aws/eks-distro/kubernetes/pause:v1.19.8-eks-1-19-4 public.ecr.aws/eks-distro/kubernetes/pause:3.2;\

sudo kubeadm join <IPaddress>:6443  --token ${TOKEN}  --discovery-token-ca-cert-hash sha256:${CERT_HASH}

# kiosk
sudo multipass set local.driver=lxd
sudo multipass set local.bridged-network=mpbr0

sudo snap connect ubuntu-frame:login-session-control
sudo snap connect wpe-webkit-mir-kiosk:wayland
sudo snap connect multipass:wayland 
sudo snap connect multipass:removable-media

sudo snap set ubuntu-frame daemon=true
sudo snap set wpe-webkit-mir-kiosk daemon=true
sudo snap set wpe-webkit-mir-kiosk url=${KIOSK_URL}

sudo systemctl status snap.wpe-webkit-mir-kiosk.daemon.service

## cumulus
sudo docker container create \
    --privileged \
    --restart always \
    --network host \
    --name cumulus \
    -it networkop/cx:4.4.0

sudo docker container start cumulus
