Provision a k8s cluster with below:
- Terraform for deploying resource on Azure
  - Shared resource:
    - Vnet: k8s-vnet
    - UserAssignedIdentity: k8s-uai
  - Baston:
    - Subnet: k8s-baston-subnet
    - Nsg: k8s-baston-nsg
      - Allow Inbound port 22 
    - Nic: k8s-baston-nic
    - Public IP: k8s-baston-pip
    - VM: k8s-baston
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

- Kubeadm for building a k8s cluster

- Calico for building Container Networking


Provision.sh -> scripts/main.sh -> containerd.sh -> k8s_install.sh -> k8s_conf_master.sh/k8s_conf_agent.sh -> calico.sh
![k8s_infra_process](https://github.com/Shuanglu/k8s_infra_azure/blob/dev/doc/images/k8s_infra_process.jpg)
