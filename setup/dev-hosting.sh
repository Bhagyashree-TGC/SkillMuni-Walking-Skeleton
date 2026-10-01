#!/usr/bin/env bash
# Creates the dev site for SkillMuni Frontend: an Azure Storage static website in Central India.
# Dev only — synthetic data, no personal data. Cost: storage and traffic only (a few US dollars a month at most).
# Production hosting is a separate decision (D-036) and is NOT created here.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "${HERE}/config.env"

az account set --subscription "$DEV_SUBSCRIPTION"
TAGS=(program=skillmuni project=skillmuni-frontend environment=dev region=india client=tgc)

az group create --name "$DEV_RESOURCE_GROUP" --location "$LOCATION" --tags "${TAGS[@]}" --only-show-errors >/dev/null
echo "Resource group ready: $DEV_RESOURCE_GROUP"

if ! az storage account show --name "$DEV_STORAGE_ACCOUNT" --resource-group "$DEV_RESOURCE_GROUP" >/dev/null 2>&1; then
  az storage account create --name "$DEV_STORAGE_ACCOUNT" --resource-group "$DEV_RESOURCE_GROUP" \
    --location "$LOCATION" --sku Standard_LRS --kind StorageV2 \
    --min-tls-version TLS1_2 --https-only true --allow-blob-public-access false \
    --tags "${TAGS[@]}" --only-show-errors >/dev/null
  echo "Storage account created: $DEV_STORAGE_ACCOUNT"
else
  echo "Storage account exists: $DEV_STORAGE_ACCOUNT"
fi

# Static website; index.html also serves unknown paths so Angular routes work on refresh.
az storage blob service-properties update --account-name "$DEV_STORAGE_ACCOUNT" \
  --static-website --index-document index.html --404-document index.html --only-show-errors >/dev/null

DEV_URL="$(az storage account show --name "$DEV_STORAGE_ACCOUNT" --resource-group "$DEV_RESOURCE_GROUP" \
  --query primaryEndpoints.web -o tsv)"

cat <<TXT

Dev site ready: ${DEV_URL}

Next:
  1. Give the 'skillmuni-dev' service connection's identity 'Storage Blob Data Contributor'
     on ${DEV_STORAGE_ACCOUNT} only.
  2. In Library > skillmuni-frontend-factory set:
       devStorageAccount = ${DEV_STORAGE_ACCOUNT}
       devUrl            = ${DEV_URL}
  3. Anyone with the URL can open the dev site. Use synthetic data only. If the dev site must be
     private, tell the factory team: it then needs Front Door or a private endpoint (extra cost).
TXT
