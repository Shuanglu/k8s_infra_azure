#!/bin/bash

k8s_install() {
  command=$(lsmod | grep br_netfilter)
  if [ -z "$command" ]; then
    modprobe br_netfilter
  fi
  if [ -s "/etc/sysctl.d/k8s.conf" ]; then
    rm -rf /etc/sysctl.d/k8s.conf
  fi
  cat <<EOF > /etc/sysctl.d/k8s.conf
  net.bridge.bridge-nf-call-ip6tables = 1
  net.bridge.bridge-nf-call-iptables = 1
  net.ipv4.ip_forward = 1
EOF
  sysctl --system
    
  apt-get install -y apt-transport-https curl
    
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
  deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
    
  apt-get update
  apt-get install -y kubelet=1.19.1-00 kubeadm=1.19.1-00 kubectl=1.19.1-00
  apt-mark hold kubelet kubeadm kubectl
}
