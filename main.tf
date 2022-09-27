###########################################################################
## Terraform script to create Windows VM and dependent resources in Azure
###########################################################################

#########################################################
## Create Resource Group
#########################################################
resource "azurerm_resource_group" "vm" {
  name     = "hashicorp-demo-rg"
  location = var.location
}

#########################################################
## Create VNet
#########################################################
module "vnet" {
  source              = "github.com/dipesharora/terraform-azure-vnet"
  resource_group_name = azurerm_resource_group.vm.name
  location            = var.location
  vnet_name           = var.vnet_name
  vnet_address_space  = var.vnet_address_space
  tags = {
    Workload = "HashiCorp Demo"
  }
}

#########################################################
## Create Subnet
#########################################################
module "subnet" {
  source                  = "github.com/dipesharora/terraform-azure-subnet?ref=2.0.0"
  resource_group_name     = azurerm_resource_group.vm.name
  vnet_name               = module.vnet.vnet_name_output
  subnet_name             = var.subnet_name
  subnet_address_prefixes = var.subnet_address_prefixes
}

#########################################################
## Create Network Security Group
#########################################################
module "nsg" {
  source              = "github.com/dipesharora/terraform-azure-nsg"
  resource_group_name = azurerm_resource_group.vm.name
  location            = var.location
  nsg_name            = var.nsg_name
  tags = {
    Workload = "HashiCorp Demo"
  }
}

#########################################################
## Create Network Security Group and Subnet Association
#########################################################
module "subnet-nsg-association" {
  source    = "github.com/dipesharora/terraform-azure-subnet-nsg-association"
  subnet_id = module.subnet.subnet_id_output
  nsg_id    = module.nsg.nsg_id_output
}

########################################################
# Create Network Security Rules for Windows VMs
########################################################
module "nsgrule_HTTP_Port_80" {
  source                              = "github.com/dipesharora/terraform-azure-nsg-rule"
  resource_group_name                 = azurerm_resource_group.vm.name
  nsg_name                            = module.nsg.nsg_name_output
  nsg_rule_status                     = var.nsg_rule_http_port_80_status
  nsg_rule_name                       = "HTTP_Port_80"
  nsg_rule_priority                   = 100
  nsg_rule_direction                  = "Inbound"
  nsg_rule_access                     = "Allow"
  nsg_rule_protocol                   = "Tcp"
  nsg_rule_source_address_prefix      = var.nsg_rule_http_port_80_source_address
  nsg_rule_source_port_range          = "*"
  nsg_rule_destination_address_prefix = var.nsg_rule_http_port_80_destination_address
  nsg_rule_destination_port_range     = "80"
  nsg_rule_description                = "Allow HTTP Traffic on Port 80."
}

module "nsgrule_HTTPS_Port_443" {
  source                              = "github.com/dipesharora/terraform-azure-nsg-rule"
  resource_group_name                 = azurerm_resource_group.vm.name
  nsg_name                            = module.nsg.nsg_name_output
  nsg_rule_status                     = var.nsg_rule_https_port_443_status
  nsg_rule_name                       = "HTTPS_Port_443"
  nsg_rule_priority                   = 110
  nsg_rule_direction                  = "Inbound"
  nsg_rule_access                     = "Allow"
  nsg_rule_protocol                   = "Tcp"
  nsg_rule_source_address_prefix      = var.nsg_rule_https_port_443_source_address
  nsg_rule_source_port_range          = "*"
  nsg_rule_destination_address_prefix = var.nsg_rule_https_port_443_destination_address
  nsg_rule_destination_port_range     = "443"
  nsg_rule_description                = "Allow HTTPS Traffic on Port 443."
}

module "nsgrule_SSH_Port_22" {
  source                              = "github.com/dipesharora/terraform-azure-nsg-rule"
  resource_group_name                 = azurerm_resource_group.vm.name
  nsg_name                            = module.nsg.nsg_name_output
  nsg_rule_status                     = var.nsg_rule_ssh_port_22_status
  nsg_rule_name                       = "SSH_Port_22"
  nsg_rule_priority                   = 1000
  nsg_rule_direction                  = "Inbound"
  nsg_rule_access                     = "Allow"
  nsg_rule_protocol                   = "Tcp"
  nsg_rule_source_address_prefix      = var.nsg_rule_ssh_port_22_source_address
  nsg_rule_source_port_range          = "*"
  nsg_rule_destination_address_prefix = var.nsg_rule_ssh_port_22_destination_address
  nsg_rule_destination_port_range     = "22"
  nsg_rule_description                = "Allow SSH on Port 22."
}

#########################################################
## Create Ubuntu VM & dependent resources
#########################################################

# Retrieve information about the HCP Packer "iteration"
data "hcp_packer_iteration" "ubuntu2204lts_iteration" {
  bucket_name = "ubuntu-2204-lts"
  channel     = "release"
}

# Retrieve information about the HCP Packer "image"
data "hcp_packer_image" "ubuntu2204lts_image" {
  bucket_name    = "ubuntu-2204-lts"
  iteration_id   = data.hcp_packer_iteration.ubuntu2204lts_iteration.id
  cloud_provider = "azure"
  region         = "East US"
}

# Retrieve Public Key from Azure
data "azurerm_ssh_public_key" "ssh" {
  name                = "DATest"
  resource_group_name = "KeyVault"
}

module "ubuntuvm" {
  source                            = "github.com/dipesharora/terraform-azure-ubuntu-vm-image"
  location                          = var.location
  resource_group_name               = azurerm_resource_group.vm.name
  nic_subnet_id                     = module.subnet.subnet_id_output
  vm_count                          = var.vm_count
  vm_prefix                         = var.vm_prefix
  vm_size                           = var.vm_size
  vm_os_disk_caching                = var.vm_os_disk_caching
  vm_os_disk_storage_account_type   = var.vm_os_disk_storage_account_type
  vm_os_disk_size                   = var.vm_os_disk_size
  vm_image_id                       = data.hcp_packer_image.ubuntu2204lts_image.cloud_image_id
  vm_admin_username                 = var.vm_admin_username
  vm_public_key                     = data.azurerm_ssh_public_key.ssh.public_key
  vm_data_disk_size_list            = var.vm_data_disk_size_list
  vm_data_disk_storage_account_type = var.vm_data_disk_storage_account_type
  vm_data_disk_create_option        = var.vm_data_disk_create_option
  vm_data_disk_caching              = var.vm_data_disk_caching
  tags = {
    Workload = "HashiCorp Demo"
  }
}