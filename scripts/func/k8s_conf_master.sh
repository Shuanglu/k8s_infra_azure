#!/bin/bash

k8s_conf_master() {
  echo 'Start kubeadm'
  echo "Clean up the node"
  echo 'Kubeadm reset'
  kubeadm reset -f
  echo "Clean up the 'kubernetes' and 'CNI' folder"
  rm -rf /etc/kubernetes
  rm -rf /etc/cni
  if [ "$3" == "Yes"]; then
    echo 'Modify the hostname and DNS name of the master in kubeadm.conf'
    if [ -f "/var/log/scripts/conf/kubeadm.conf" ]; then
      echo 'Modify the token'
      sed -i "s/  token:.*/  token: $1/g" /var/log/scripts/conf/kubeadm.conf
      echo 'Modify the apiserver endpoint'
      sed -i "s/controlPlaneEndpoint:.*/controlPlaneEndpoint: $2:443/g" /var/log/scripts/conf/kubeadm.conf
      echo 'Modify done'
    fi
    echo 'Copy the azure.json/CA pair to /etc/kubernetes/'
    mkdir -p /etc/kubernetes/pki
    cp /var/log/scripts/conf/ca* /etc/kubernetes/pki/
    cp /var/log/scripts/conf/azure.json /etc/kubernetes/azure.json
    echo 'kubeadm init'
    kubeadm init --config /var/log/scripts/conf/kubeadm.conf --skip-phases certs/ca 
  else [ "$3" == "No" ]; then
   echo 'Join the control plane node'
   kubeadm join $2:443 --token $1 --discovery-token-ca-cert-hash sha256:$3 --control-plane --v=9
  fi 
  if [ $? -eq 0 ]; then
    touch /var/log/scripts/provision.complete
  else 
    exit 1
  fi

}
