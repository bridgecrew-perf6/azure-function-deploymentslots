terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.83.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "=3.1.0"
    }
  }
  backend "azurerm" {

  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

locals {
  func_name = "funcslot${random_string.unique.result}"
  loc_for_naming = lower(replace(var.location, " ", ""))
  tags = {
    "managed_by" = "terraform"
    "repo"       = "azure-function-deploymentslots"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.func_name}-${local.loc_for_naming}"
  location = var.location
}

resource "random_string" "unique" {
  length  = 8
  special = false
  upper   = false
}


data "azurerm_client_config" "current" {}

data "azurerm_log_analytics_workspace" "default" {
  name                = "DefaultWorkspace-${data.azurerm_client_config.current.subscription_id}-EUS"
  resource_group_name = "DefaultResourceGroup-EUS"
} 

data "azurerm_network_security_group" "basic" {
    name                = "basic"
    resource_group_name = "rg-network-eastus"
}

module "func1" {
    source   = "github.com/implodingduck/tfmodules//functionapp"
    func_name = "fundeploymentslots"
    resource_group_name = azurerm_resource_group.rg.name
    resource_group_location = azurerm_resource_group.rg.location
    working_dir = "../funcactive"
    app_settings = {
      "FUNCTIONS_WORKER_RUNTIME" = "node"
    }
    linux_fx_version = "node|14"
    app_identity = [{ 
      type = "SystemAssigned"
      identity_ids = null
    }]
}

# resource "azurerm_function_app_slot" "checkout" {
#   name                       = "checkout"
#   location                   = azurerm_resource_group.rg.location
#   resource_group_name        = azurerm_resource_group.rg.name
#   app_service_plan_id        = module.func1.asp_id
#   function_app_name          = module.func1.funcion_name
#   storage_account_name       = module.func1.storage_account_name
#   storage_account_access_key = module.func1.storage_account_key
# }