#########################################################
## Terraform Version Used
#########################################################
terraform {
  required_version = "=1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.24.0"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = "=0.44.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "hcp" {}