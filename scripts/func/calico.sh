#!/bin/bash

install_calico() {
  echo "Start configuring the Calico"
  echo "Install tigera operator"
  kubectl  --kubeconfig=/etc/kubernetes/admin.conf apply -f conf/tigera-operator.yaml

  echo "Install calico"
  kubectl  --kubeconfig=/etc/kubernetes/admin.conf apply -f conf/custom-resources.yaml
}
