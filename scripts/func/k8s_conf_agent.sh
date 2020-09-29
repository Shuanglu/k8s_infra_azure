#!/bin/bash

k8s_conf_agent() {
  echo 'Start kubeadm'
  echo "Clean up the node"
  echo 'Kubeadm reset'
  kubeadm reset -f
  echo "Clean up the 'kubernetes' and 'CNI' folder"
  rm -rf /etc/kubernetes
  rm -rf /etc/cni
  mkdir -p /etc/kubernetes/
  cp /var/log/scripts/conf/azure.json /etc/kubernetes/azure.json
  echo 'kubeadm join'
  #set -x
  kubeadm join $2:443 --token $1 --discovery-token-ca-cert-hash sha256:$3 --v=9
  #set +x
  if [ $? -eq 0 ]; then
    touch /var/log/scripts/provision.complete
  else 
    exit 1
  fi 
}
