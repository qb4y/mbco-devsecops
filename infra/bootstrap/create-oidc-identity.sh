set -euo pipefail

GITHUB_REPO="${GITHUB_REPO:?Indica el repo, por ejemplo: GITHUB_REPO=usuario/mbco-devsecops}"
APP_NAME="${APP_NAME:-sp-mbco-github-actions}"
RG_NAME="${RG_NAME:-rg-mbco-tfstate}"
STORAGE_NAME="${STORAGE_NAME:-stmbcotfstate}"
ENVIRONMENT_NAME="${ENVIRONMENT_NAME:-production}"

ACRPULL_ROLE_ID="7f951dda-4ed3-4680-a7ca-43fe172d538d"

SUB_ID="$(az account show --query id -o tsv)"
TENANT_ID="$(az account show --query tenantId -o tsv)"

if [ -z "${SUBJECT_PREFIX:-}" ]; then
  REPO_INFO="$(curl -fsS "https://api.github.com/repos/$GITHUB_REPO")"
  OWNER_ID="$(jq -r .owner.id <<<"$REPO_INFO")"
  REPO_ID="$(jq -r .id <<<"$REPO_INFO")"
  OWNER="${GITHUB_REPO%%/*}"
  NAME="${GITHUB_REPO##*/}"
  SUBJECT_PREFIX="repo:${OWNER}@${OWNER_ID}/${NAME}@${REPO_ID}"
fi
echo "Subject OIDC base: $SUBJECT_PREFIX"

APP_ID="$(az ad app list --display-name "$APP_NAME" --query "[0].appId || ''" -o tsv)"
if [ -z "$APP_ID" ]; then
  APP_ID="$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)"
  echo "App creada: $APP_ID"
else
  echo "App ya existe: $APP_ID"
fi

SP_ID="$(az ad sp list --filter "appId eq '$APP_ID'" --query "[0].id || ''" -o tsv)"
if [ -z "$SP_ID" ]; then
  SP_ID="$(az ad sp create --id "$APP_ID" --query id -o tsv)"
  echo "Service principal creado: $SP_ID"
fi

create_credential() {
  local name="$1" subject="$2" existing
  existing="$(az ad app federated-credential list --id "$APP_ID" \
    --query "[?name=='$name'].name | [0] || ''" -o tsv)"
  if [ -n "$existing" ]; then
    echo "Credencial ya existe: $name"
    return
  fi
  az ad app federated-credential create --id "$APP_ID" --output none --parameters "{
    \"name\": \"$name\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"$subject\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"
  echo "Credencial creada: $name"
}

create_credential "github-main" "$SUBJECT_PREFIX:ref:refs/heads/main"
create_credential "github-pull-request" "$SUBJECT_PREFIX:pull_request"
create_credential "github-env-$ENVIRONMENT_NAME" "$SUBJECT_PREFIX:environment:$ENVIRONMENT_NAME"

assign_role() {
  local role="$1" scope="$2" condition="${3:-}" count
  count="$(az role assignment list --assignee "$SP_ID" --role "$role" --scope "$scope" \
    --query "length(@)" -o tsv)"
  if [ "$count" != "0" ]; then
    echo "Rol ya asignado: $role"
    return
  fi
  if [ -n "$condition" ]; then
    az role assignment create --assignee-object-id "$SP_ID" \
      --assignee-principal-type ServicePrincipal --role "$role" --scope "$scope" \
      --condition "$condition" --condition-version "2.0" --output none
  else
    az role assignment create --assignee-object-id "$SP_ID" \
      --assignee-principal-type ServicePrincipal --role "$role" --scope "$scope" \
      --output none
  fi
  echo "Rol asignado: $role"
}

STORAGE_ID="$(az storage account show --name "$STORAGE_NAME" --resource-group "$RG_NAME" --query id -o tsv)"

assign_role "Contributor" "/subscriptions/$SUB_ID"
assign_role "Storage Blob Data Contributor" "$STORAGE_ID"
CONDITION="((!(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})) OR (@Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {$ACRPULL_ROLE_ID})) AND ((!(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})) OR (@Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {$ACRPULL_ROLE_ID}))"
assign_role "Role Based Access Control Administrator" "/subscriptions/$SUB_ID" "$CONDITION"

cat <<EOF

Listo. Crea estas variables en GitHub (Settings > Secrets and variables > Actions > Variables):
  AZURE_CLIENT_ID        = $APP_ID
  AZURE_TENANT_ID        = $TENANT_ID
  AZURE_SUBSCRIPTION_ID  = $SUB_ID
EOF
