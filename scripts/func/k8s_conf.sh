#!/bin/bash

k8s_conf() {
  echo 'Configuring k8s'
  echo 'Copy the azure.json'
  if [ -f "/etc/kubernetes/azure.json" ]; then
    rm -rf /etc/kubernetes/azure.json
  fi
  cp /var/log/scripts/conf/azure.json /etc/kubernetes/azure.json
  echo 'Modify the hostname and DNS name of the master in kubeadm.conf'
  if [ -f "/var/log/scripts/conf/kubeadm.conf" ]; then
    echo 'Mify the hostname' 
    hostname=`hostname`
    sed -i "s/  name:.*/  name: $hostname/g" /var/log/scripts/conf/kubeadm.conf
    echo 'Modify the apiserver endpoint'
    sed -i "s/controlPlaneEndpoint:.*/controlPlaneEndpoint: k8s-master-pip.westus2.cloudapp.azure.com:443/g" /var/log/scripts/conf/kubeadm.conf
    echo 'moddify done'
  fi
  echo 'kubeadm init'
  kubeadm reset -f
  kubeadm init --config /var/log/scripts/conf/kubeadm.conf  
}