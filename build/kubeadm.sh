#!/bin/bash

# modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

# sysconfig
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

# kubeadm
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-add-repository "deb https://apt.kubernetes.io/ kubernetes-xenial main"

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# eks
wget https://distro.eks.amazonaws.com/kubernetes-1-19/releases/4/artifacts/kubernetes/v1.19.8/bin/linux/$(dpkg --print-architecture)/kubelet; \
wget https://distro.eks.amazonaws.com/kubernetes-1-19/releases/4/artifacts/kubernetes/v1.19.8/bin/linux/$(dpkg --print-architecture)/kubeadm; \
wget https://distro.eks.amazonaws.com/kubernetes-1-19/releases/4/artifacts/kubernetes/v1.19.8/bin/linux/$(dpkg --print-architecture)/kubectl
chmod +x kubeadm kubectl kubelet
sudo rm /usr/bin/{kubelet,kubeadm,kubectl}
sudo mv kubeadm kubectl kubelet /usr/bin/

# kubernetes
sudo systemctl enable kubelet

sudo mkdir -p /var/lib/kubelet
cat <<EOF | sudo tee /var/lib/kubelet/kubeadm-flags.env
KUBELET_KUBEADM_ARGS="--cgroup-driver=systemd —network-plugin=cni —pod-infra-container-image=public.ecr.aws/eks-distro/kubernetes/pause:3.2"
EOF

sudo docker pull public.ecr.aws/eks-distro/kubernetes/pause:v1.19.8-eks-1-19-4;\
sudo docker pull public.ecr.aws/eks-distro/coredns/coredns:v1.8.0-eks-1-19-4;\
sudo docker pull public.ecr.aws/eks-distro/etcd-io/etcd:v3.4.14-eks-1-19-4;\
sudo docker tag public.ecr.aws/eks-distro/kubernetes/pause:v1.19.8-eks-1-19-4 public.ecr.aws/eks-distro/kubernetes/pause:3.2;\
sudo docker tag public.ecr.aws/eks-distro/coredns/coredns:v1.8.0-eks-1-19-4 public.ecr.aws/eks-distro/kubernetes/coredns:1.7.0;\
sudo docker tag public.ecr.aws/eks-distro/etcd-io/etcd:v3.4.14-eks-1-19-4 public.ecr.aws/eks-distro/kubernetes/etcd:3.4.13-0
