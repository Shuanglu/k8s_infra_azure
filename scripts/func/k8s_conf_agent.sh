#!/bin/bash

k8s_conf_agent() {
  token=$1 
  master_fqdn=$2 
  scriptblob=$3 
  confblob=$4
  first=$5

  echo 'Start kubeadm'
  echo "Clean up the node"
  echo 'Kubeadm reset'
  kubeadm reset -f
  echo "Clean up the 'kubernetes' and 'CNI' folder"
  rm -rf /etc/kubernetes
  rm -rf /etc/cni
  mkdir -p /etc/kubernetes/
  cp /var/log/scripts/conf/ca* /etc/kubernetes/pki/
  cp /var/log/scripts/conf/azure.json /etc/kubernetes/azure.json
  ca_hash=`openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'`

  echo 'kubeadm join'
  set -x
  kubeadm join $master_fqdn:443 --token $token --discovery-token-ca-cert-hash sha256:$ca_hash --v=9
  set +x
  if [ $? -eq 0 ]; then
    touch /var/log/scripts/provision.complete
  else 
    exit 1
  fi 
}
