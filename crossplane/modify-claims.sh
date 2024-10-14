#!/bin/bash

set -euo pipefail

# Input JSON from Terraform
eval "$(jq -r '@sh "FOLDER_PATH=\(.folder_path) VAULT_ID=\(.vault_id)"')"

# Predefined array of claim types to process
CLAIM_TYPES=("XLykonLambda" "XLykonLambdaDockerImage")

# Iterate over all YAML files in the specified folder
for file in "$FOLDER_PATH"/*.yaml; do
  # Check if the kind matches one of the claim types we're interested in
  kind=$(yq eval '.kind' "$file")
  if [[ " ${CLAIM_TYPES[@]} " =~ " ${kind} " ]]; then
    # Extract service_name to use for fetching secrets
    srv_name=$(yq eval '.spec.parameters.service_name' "$file")

    if [[ -z "$srv_name" ]]; then
      echo "Warning: service_name is not defined in $file, skipping secret fetching."
      continue
    fi

    # Fetch secrets based on srv_name (using 1Password CLI as an example)
    secrets=$(op items get "$srv_name" --vault="$VAULT_ID" --format=json | jq '.fields | map({(.label): .value}) | add')

    if [[ -z "$secrets" ]]; then
      echo "Warning: Failed to fetch secrets for $srv_name, skipping secret addition."
      continue
    fi

    # Add secrets to the YAML
    yq eval ".spec.parameters.secrets = $secrets" -i "$file"
  fi

  # Convert the final YAML to JSON for Terraform
  manifest=$(yq eval -j "$file")
  jq -n --arg manifest "$manifest" '{ manifest: $manifest }'
done
