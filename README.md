# terraform-azurerm-oneormanylinuxVM
Terraform code for deploying one or many Linux VM on Azure

= Tested with success with Terraform v0.12.18 + Azurerm provider version v1.39.0 - 3rd of january 2020

--------------------------------------------------------------------------------------------------------
This is a set of Terraform files used to deploy one or many Linux Virtual Machines on Microsoft Azure :

- __datasource.tf__ : define a datasource to retrieve a Public SSH Key stored as a secret in an Azure Key Vault
- __var.tf__ : contains definition of all variables used in main.tf. Some variables have default values
- __main.tf__ : contains code to deploy an Azure Resource Group, a VNet, a Subnet, an Availability Set, 1 to N Linux virtual machine(s) with an additional data disk, a Network Security Group
- __versions.tf__ : contains minimal version of Terraform to use

__Prerequisites :__
- An Azure Subscription with enough privileges (create RG, AKS...)
- Azure CLI 2.0.78 : https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest
- Terraform CLI 0.12.12 or > : https://www.terraform.io/downloads.html

__To deploy this infrastructure :__
1. Log to your Azure subscription (az login)
2. Create an Azure Key Vault and create a secret named "clePubliqueSSH" that contains your public SSH Key
3. Define the value of each variable in .tf and .tfvars files
4. Initialize your terraform deployment : terraform init
5. Plan your terraform deployment : `terraform plan --var-file=myconf.tfvars`
6. Apply your terraform deployment : `terraform apply --var-file=myconf.tfvars`

__For more information about Terraform & Azure, few additional online resources :__
- My blog (for those who understand french) : https://stanislas.io
- Terraform documentation : https://www.terraform.io/docs/providers/azurerm/r/kubernetes_cluster.html
- Azure Terraform Provider : https://github.com/terraform-providers/terraform-provider-azurerm
- Azure Terraform Provider Virtual Machine : https://www.terraform.io/docs/providers/azurerm/r/virtual_machine.html
