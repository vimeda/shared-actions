#!/bin/bash

set -euov pipefail

# Ensure the tmp/ folder exists in the current working directory
mkdir -p tmp/

# Extract variables using jq
eval "$(jq -r '@sh "ENV=\(.env) VAULT_ID=\(.vault_id) CLAIM_YAML=\(.claim_yaml)"')"

# Generate a SHA256 hash from CLAIM_YAML and use part of it for the file name
hash=$(echo -n "$CLAIM_YAML" | sha256sum | cut -d' ' -f1)

# Create a temporary file in the tmp/ folder, prefixed with 'tmpfile_' and suffixed with the hash
temp_yaml_file="tmp/tmpfile_${hash}.yaml"

# Write the input YAML to the temporary file for processing
echo "$CLAIM_YAML" > "$temp_yaml_file"

# Predefined arrays of claim types to process
CLAIM_TYPES_LAMBDA=("XLykonLambda" "XLykonLambdaDockerImage")
CLAIM_TYPES_GOAPP=("XLykonGoApp")

# Check the kind of the YAML
kind=$(yq eval '.kind' "$temp_yaml_file")

# Function to add VPC configuration based on environment
add_vpc_config() {
  local env="$1"
  local config

  if [[ "$env" == "staging" ]]; then
    config='{"vpcConfig":[{"securityGroupIds":["sg-03c24245575c1ebc0"],"subnetIds":["subnet-011cb6fe763310759","subnet-08deca209f9e46ebb","subnet-06e62ab1abfd70465"]}]}'
  elif [[ "$env" == "prod" ]]; then
    config='{"vpcConfig":[{"securityGroupIds":["sg-03c24245575c1ebc0"],"subnetIds":["subnet-011cb6fe763310759","subnet-08deca209f9e46ebb","subnet-06e62ab1abfd70465"]}]}'
  else
    echo "Error: Unsupported environment $env"
    exit 1
  fi

  yq eval ".spec.parameters += $config" -i "$temp_yaml_file"
}

if [[ " ${CLAIM_TYPES_LAMBDA[@]} " =~ " ${kind} " ]]; then
  # Handle XLykonLambda and XLykonLambdaDockerImage
  service_name=$(yq eval '.spec.parameters.service_name' "$temp_yaml_file")

  if [[ -z "$service_name" ]]; then
    echo "Warning: service_name is not defined, skipping secret fetching."
  else
    secrets=$(op items get "$service_name" --vault="$VAULT_ID" --format=json | jq '.fields | map({(.label): .value}) | add')

    if [[ -z "$secrets" ]]; then
      echo "Warning: Failed to fetch secrets for $service_name, skipping secret addition."
    else
      # Wrap secrets in an array with 'variables'
      secrets_with_variables=$(jq -n --argjson secrets "$secrets" '[{"variables": $secrets}]')

      # Update the YAML file with the secrets under 'secrets' field
      yq eval ".spec.parameters.secrets = $secrets_with_variables" -i "$temp_yaml_file"
    fi
  fi
  add_vpc_config "$ENV"  # Add VPC config only for Lambda types
elif [[ " ${CLAIM_TYPES_GOAPP[@]} " =~ " ${kind} " ]]; then
  # Handle XLykonGoApp
  if [[ "$ENV" == "staging" ]]; then
    vault_id="errsir3kqd4gdjgaxliofyskey"
  elif [[ "$ENV" == "prod" ]]; then
    vault_id="37y43e5v2qd3iptgt7wgyk34ga"
  else
    echo "Error: Unsupported environment $ENV"
    exit 1
  fi

  yq eval ".spec.parameters.vault_id = \"$vault_id\"" -i "$temp_yaml_file"
fi

# Convert the final YAML to JSON for Terraform
manifest=$(yq eval -o=json "$temp_yaml_file")
jq -n --arg manifest "$manifest" '{ manifest: $manifest }'
