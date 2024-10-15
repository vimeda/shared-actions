#!/bin/bash

set -euo pipefail

# Input JSON from Terraform
eval "$(jq -r '@sh "VAULT_ID=\(.vault_id) CLAIM_YAML=\(.claim_yaml)"')"

# Write the input YAML to a temporary file for processing
temp_yaml_file=tmp.yaml
echo "$CLAIM_YAML" > "$temp_yaml_file"

# Predefined array of claim types to process
CLAIM_TYPES=("XLykonLambda" "XLykonLambdaDockerImage")

# Check if the kind matches one of the claim types we're interested in
kind=$(yq eval '.kind' "$temp_yaml_file")
if [[ " ${CLAIM_TYPES[@]} " =~ " ${kind} " ]]; then
  # Extract service_name to use for fetching secrets
  service_name=$(yq eval '.spec.parameters.service_name' "$temp_yaml_file")

  if [[ -z "$service_name" ]]; then
    echo "Warning: service_name is not defined, skipping secret fetching."
  else
    # Verify if 1Password CLI is logged in
    if ! op vault list >/dev/null 2>&1; then
      echo "Error: Not logged in to 1Password CLI" >&2
      exit 1
    fi

    # Fetch secrets based on service_name
    secrets=$(op items get "$service_name" --vault="$VAULT_ID" --format=json | jq -c '.fields | map({(.label): .value}) | add')

    if [[ -z "$secrets" ]]; then
      echo "Warning: Failed to fetch secrets for $service_name, skipping secret addition."
    else
      # Add secrets to the YAML
      yq eval ".spec.parameters.secrets = \"$secrets\"" -i "$temp_yaml_file"
    fi
  fi
fi

# Convert the final YAML to JSON for Terraform
manifest=$(yq eval -o=json "$temp_yaml_file")
jq -n --arg manifest "$manifest" '{ manifest: $manifest }'
