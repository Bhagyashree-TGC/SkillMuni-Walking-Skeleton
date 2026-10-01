#!/usr/bin/env bash
# Creates the immutable evidence vault (D-055) in the factory subscription, India region.
# The immutability policy is created UNLOCKED. Locking it is irreversible: it needs
# Level 1 and Level 2 approval (D-059) and the Compliance Lead's agreement on retention.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "${HERE}/config.env"

az account set --subscription "$AZ_SUBSCRIPTION"

az group create --name "$RESOURCE_GROUP" --location "$LOCATION" \
  --tags program=factory project=evidence-vault environment=prod region=india --only-show-errors >/dev/null
echo "Resource group ready: $RESOURCE_GROUP"

if ! az storage account show --name "$EVIDENCE_ACCOUNT" --resource-group "$RESOURCE_GROUP" >/dev/null 2>&1; then
  az storage account create --name "$EVIDENCE_ACCOUNT" --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" --sku Standard_ZRS --kind StorageV2 \
    --min-tls-version TLS1_2 --allow-blob-public-access false --allow-shared-key-access false \
    --https-only true \
    --tags program=factory project=evidence-vault environment=prod region=india --only-show-errors >/dev/null
  echo "Storage account created: $EVIDENCE_ACCOUNT (zone-redundant, no public access, no shared keys)"
else
  echo "Storage account exists: $EVIDENCE_ACCOUNT"
fi

az storage account blob-service-properties update --account-name "$EVIDENCE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" --enable-versioning true \
  --enable-delete-retention true --delete-retention-days 35 --only-show-errors >/dev/null
echo "Versioning and 35-day soft delete on."

az storage container create --name evidence --account-name "$EVIDENCE_ACCOUNT" \
  --auth-mode login --only-show-errors >/dev/null
echo "Container ready: evidence"

az storage container immutability-policy create --account-name "$EVIDENCE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" --container-name evidence \
  --period "$RETENTION_DAYS" --allow-protected-append-writes true --only-show-errors >/dev/null
echo "Time-based retention of ${RETENTION_DAYS} days set (UNLOCKED)."

cat <<TXT

Next:
  1. Grant the 'factory-evidence' service connection's identity the role
     'Storage Blob Data Contributor' on ${EVIDENCE_ACCOUNT} (data writes only).
  2. Set evidenceStorageAccount: ${EVIDENCE_ACCOUNT} in both pipeline files.
  3. After the Compliance Lead confirms retention, and with both approvals, lock the policy:
     az storage container immutability-policy lock ... (irreversible)
TXT
