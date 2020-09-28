#!/bin/bash

k8s_conf() {
  echo 'Configuring k8s'

  hostname=`hostname`
  validation=`echo $hostname | grep -o 'k8s-master'`
  if [ "$validation" == "k8s-master" ]; then
    echo 'Provisioning master'
    echo 'Modify the hostname and DNS name of the master in kubeadm.conf'
    if [ -f "/var/log/scripts/conf/kubeadm.conf" ]; then
      echo 'modify the hostname' 
      sed -i "s/  name:.*/  name: $hostname/g" /var/log/scripts/conf/kubeadm.conf
      echo 'modify the apiserver endpoint'
      sed -i "s/controlPlaneEndpoint:.*/controlPlaneEndpoint: k8s-master-pip.westus2.cloudapp.azure.com:443/g" /var/log/scripts/conf/kubeadm.conf
      echo 'modify done'
    fi
    echo 'kubeadm provision'
    echo 'kubeadm reset'
    kubeadm reset -f >> /var/log/scripts/initilization.log 2>&1
    if [ -d "/var/lib/etcd" ]; then
      rm -rf /var/lib/etcd
    fi
    echo 'Copy the azure.json'
    rm -rf /etc/kubernetes
    mkdir -p /etc/kubernetes/pki
    cp /var/log/scripts/conf/ca* /etc/kubernetes/pki/
    cp /var/log/scripts/conf/azure.json /etc/kubernetes/azure.json
    kubeadm init --config /var/log/scripts/conf/kubeadm.conf --skip-phases certs/ca >> /var/log/scripts/initilization.log 2>&1
    if [ $? -eq 0 ]; then
      touch /var/log/scripts/provision.complete
      exit 0
    else 
      exit 1
    fi 
  fi

  validation=`echo $hostname | grep -o 'k8s-agent'`
  if [ "$validation" == "k8s-agent" ]; then
    echo 'kubeadm reset'
    kubeadm reset -f >> /var/log/scripts/initilization.log 2>&1
    echo 'kubeadm join'
    set -x
    kubeadm join k8s-master-pip.westus2.cloudapp.azure.com:443 --token 'abcdef.0123456789abcdef' --discovery-token-ca-cert-hash 'sha256:372c9fab34e6a29eb795ffcbe86fb7b1e3efbd1b8fe61422c405c6758bff051d' --v=9
    set +x
  fi
}
