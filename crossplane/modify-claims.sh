#!/bin/bash

set -euov pipefail

# Ensure the tmp/ folder exists in the current working directory
mkdir -p tmp/

# Extract variables using jq
eval "$(jq -r '@sh "VAULT_ID=\(.vault_id) CLAIM_YAML=\(.claim_yaml)"')"

# Generate a SHA256 hash from CLAIM_YAML and use part of it for the file name
hash=$(echo -n "$CLAIM_YAML" | sha256sum | cut -d' ' -f1)

# Create a temporary file in the tmp/ folder, prefixed with 'tmpfile_' and suffixed with the hash
temp_yaml_file="tmp/tmpfile_${hash}.yaml"

# Write the input YAML to the temporary file for processing
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
    # Fetch secrets based on service_name
    secrets=$(op items get "$service_name" --vault="$VAULT_ID" --format=json | jq '.fields | map({(.label): .value}) | add')

    if [[ -z "$secrets" ]]; then
      echo "Warning: Failed to fetch secrets for $service_name, skipping secret addition."
    else
      # Add secrets to the YAML
      yq eval ".spec.parameters.secrets = $secrets" -i "$temp_yaml_file"
    fi
  fi
fi

# Convert the final YAML to JSON for Terraform
manifest=$(yq eval -o=json "$temp_yaml_file")
jq -n --arg manifest "$manifest" '{ manifest: $manifest }'
