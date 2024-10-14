data "template_file" "claims" {
  for_each = fileset("../${var.service_name}/configs/crossplane/${terraform.workspace}", "*.yaml")
  template = file("../${var.service_name}/configs/crossplane/${terraform.workspace}/${each.value}")

  vars = {
    commit_hash = var.commit_hash
    service_name = var.service_name
  }
}

# Use external data source to run the bash script to modify the claims
data "external" "modified_yaml" {
  for_each = data.template_file.claims
  program = ["bash", "${path.module}/modify-claims.sh"]

  query = {
    vault_id   = var.vault_id
    claim_yaml = each.value.rendered  # Pass the rendered YAML content
  }
}

locals {
  # Use the modified YAML from the external script and add the commit hash and vault ID
  updated_yaml_maps = [
    for claim in data.template_file.claims : merge(
      yamldecode(claim.rendered),
      {
        spec = {
          parameters = merge(
            lookup(yamldecode(claim.rendered), "spec", {})["parameters"],
            {
              image_tag = var.commit_hash,
              vault_id  = var.vault_id
            }
          )
        }
      }
    )
  ]

  # Convert each updated_yaml_map to a YAML string
  updated_yaml_intermediate = join("\n---\n", [for yaml_map in local.updated_yaml_maps : yamlencode(yaml_map)])
  updated_yaml = join("\n---\n", [for yaml_map in data.external.modified_yaml : yamlencode(yaml_map.result.manifest)])
}

resource "local_file" "output_yaml" {
  filename = "${var.service_name}/configs/crossplane/${terraform.workspace}/manifest.yaml"
  content  = local.updated_yaml
}

data "kubectl_file_documents" "claims" {
  content = local.updated_yaml
}

resource "kubectl_manifest" "claim" {
  for_each  = data.kubectl_file_documents.claims.manifests
  yaml_body = each.value
}
