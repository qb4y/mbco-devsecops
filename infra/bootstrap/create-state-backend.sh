#! /usr/bin/env bash
set -euo pipefail

RG_NAME="${RG_NAME:-rg-mbco-tfstate}"
LOCATION="${LOCATION:-eastus2}"
STORAGE_NAME="${STORAGE_NAME:-stmbcotfstate}"
CONTAINER_NAME="${CONTAINER_NAME:-tfstate}"

# 1) Resource group
az group create --name "$RG_NAME" --location "$LOCATION"

# 2) Storage account
az storage account create \
  --name "$STORAGE_NAME" \
  --resource-group "$RG_NAME" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

# 3) Contenedor
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_NAME" \
  --auth-mode login