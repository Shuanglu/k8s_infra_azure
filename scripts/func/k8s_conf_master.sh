#!/bin/bash

k8s_conf_master() {
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
  echo 'Copy the azure.json/CA pair/audit policy to /etc/kubernetes/'
  mkdir -p /etc/kubernetes/pki
  mkdir -p /etc/kubernetes/audit
  cp /var/log/scripts/conf/ca* /etc/kubernetes/pki/
  cp /var/log/scripts/conf/azure.json /etc/kubernetes/azure.json
  cp /var/log/scripts/conf/audit-policy.yaml /etc/kubernetes/audit/audit-policy.yaml
  ca_hash=`openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'`

  if [ "$first" == "Yes" ]; then
    echo 'Modify the hostname and DNS name of the master in kubeadm.conf'
    if [ -f "/var/log/scripts/conf/kubeadm.conf" ]; then
      echo 'Modify the token'
      sed -i "s/  token:.*/  token: $token/g" /var/log/scripts/conf/kubeadm.conf
      echo 'Modify the apiserver endpoint'
      sed -i "s/controlPlaneEndpoint:.*/controlPlaneEndpoint: $master_fqdn:443/g" /var/log/scripts/conf/kubeadm.conf
      echo 'Modify done'
    fi
    echo 'kubeadm init'
    kubeadm init --config /var/log/scripts/conf/kubeadm.conf --skip-phases certs/ca 
    if [ "$?" -eq 0 ]; then
      curl -X PUT -T /etc/kubernetes/admin.conf -H "x-ms-blob-type: BlockBlob" $confblob
    fi  
  elif [ "$first" == "No" ]; then
   echo 'Join the control plane node'
   kubeadm join $master_fqdn:443 --token $token --discovery-token-ca-cert-hash sha256:$ca_hash --control-plane --cri-socket /var/run/containerd/containerd.sock --v=9 
  fi 
  if [ $? -eq 0 ]; then
    touch /var/log/scripts/provision.complete
  else 
    exit 1
  fi
}
