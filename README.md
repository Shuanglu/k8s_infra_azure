[1]
Provision a k8s cluster on Azurew with below:
- Terraform for deploying resource on Azure
  - Shared resource:
    - Vnet: k8s-vnet
    - UserAssignedIdentity: k8s-uai
  - Bastion:
    - Subnet: k8s-bastion-subnet
    - Nsg: k8s-bastion-nsg
      - Allow Inbound port 22 
    - Nic: k8s-bastion-nic
    - Public IP: k8s-bastion-pip
    - VM: k8s-bastion
  - Master:
    - Subnet: k8s-master-subnet
    - Nsg: k8s-master-nsg
      - Allow Inbound port 6443
    - Public IP: k8s-master-pip
    - Loadbalancer: k8s-master-lb
    - VMSS: k8s-master
  - Agent:
    - Subnet: k8s-agent-subnet
    - Nsg: k8s-agent-nsg
    - Public IP: k8s-agent-pip
    - VMSS: k8s-agent

![k8s_infra_arch](https://github.com/Shuanglu/k8s_infra_azure/blob/dev/doc/images/k8s_infra_arch.PNG)

[2]
Kubeadm for building a k8s cluster

[3]
Deploy tigera-operator to install of Calico


Provision.sh -> scripts/main.sh -> containerd.sh -> k8s_install.sh -> k8s_conf_master.sh/k8s_conf_agent.sh -> calico.sh
![k8s_infra_process](https://github.com/Shuanglu/k8s_infra_azure/blob/dev/doc/images/k8s_infra_process.jpg)
