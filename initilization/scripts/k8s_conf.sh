#!/bin/bash

k8s_conf() {
  if [ -s "/etc/kubernetes/azure.json"]; then
    rm -rf /etc/kubernetes/azure.json
    cp /var/log/scripts/conf/azure.json /etc/kubernetes/azure.json
  fi
  kubeadm init --config /var/log/scripts/conf/kubeadm.conf  
}