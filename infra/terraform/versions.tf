terraform {
  required_version = ">= 1.17"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # El estado vive en Azure Storage para que el pipeline y yo veamos lo mismo.
  # La autenticacion es por Entra ID (OIDC), sin claves de la cuenta.
  backend "azurerm" {
    resource_group_name  = "rg-mbco-tfstate"
    storage_account_name = "stmbcotfstate"
    container_name       = "tfstate"
    key                  = "aks-mbco-reto.tfstate"
    use_oidc             = true
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
}
