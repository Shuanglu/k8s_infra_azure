package main

import (
	"fmt"

	"github.com/Azure/go-autorest/autorest/azure/auth"
)

func main() {
	fmt.Println("This is a tool to provision a k8s cluster on Azure with kubeadm. Let's start!")

	var clientID, clientSecret, tenantID string
	fmt.Println("Please input the Service Principal clinet ID: ")
	fmt.Scanf("%s", &clientID)
	fmt.Println("Please input the Service Principal clinet Secret: ")
	fmt.Scanf("%s", &clientSecret)
	fmt.Println("Please input the Service Principal tenant ID: ")
	fmt.Scanf("%s", &tenantID)
	loginConfig := auth.NewClientCredentialsConfig(clientID, clientSecret, tenantID)
	client, _ := loginConfig.Authorizer()
	fmt.Println(client)
}
