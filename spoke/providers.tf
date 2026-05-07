terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }

  backend "azurerm" {}
}

# Spoke subscription — authenticate via:
#   az login
#   az account set --subscription <spoke-subscription-id>
provider "azurerm" {
  subscription_id = var.subscription_id
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Hub subscription alias — only used to create the hub-to-spoke VNet peering
# and to link spoke DNS zones to hub VNet.
# The same az login session is used; the deployer must have Contributor on the hub VNet RG.
provider "azurerm" {
  alias           = "hub"
  subscription_id = var.hub_subscription_id
  features {}
}
