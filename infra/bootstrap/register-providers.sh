#!/usr/bin/env bash
# Registra en la suscripcion los proveedores de recursos que necesita el reto.
# Una suscripcion nueva los trae sin registrar y el error que da Azure es
# engañoso (SubscriptionNotFound). Se puede repetir sin problema.
set -euo pipefail

PROVIDERS=(
  Microsoft.Storage
  Microsoft.ContainerService
  Microsoft.ContainerRegistry
  Microsoft.Network
  Microsoft.Compute
)

for ns in "${PROVIDERS[@]}"; do
  echo "Registrando $ns ..."
  az provider register --namespace "$ns" --wait
done

az provider list \
  --query "[?contains(['Microsoft.Storage','Microsoft.ContainerService','Microsoft.ContainerRegistry','Microsoft.Network','Microsoft.Compute'], namespace)].{proveedor:namespace, estado:registrationState}" \
  --output table
