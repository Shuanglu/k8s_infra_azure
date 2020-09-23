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
      - Allow Inbound port 443
    - Public IP: k8s-master-pip
    - Loadbalancer: k8s-master-lb
    - VMSS: k8s-master
   - Agent:
    - Subnet: k8s-agent-subnet
    - Nsg: k8s-agent-nsg
      - Allow Inbound port 22
    - Public IP: k8s-agent-pip
    - Loadbalancer: k8s-agent-lb
    - VMSS: k8s-agent

- Kubeadm for building a k8s cluster

- Calico for building Container Networking