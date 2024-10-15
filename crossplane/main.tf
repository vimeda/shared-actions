data "template_file" "claims" {
  for_each = fileset("../${var.service_name}/configs/crossplane/${terraform.workspace}", "*.yaml")
  template = file("../${var.service_name}/configs/crossplane/${terraform.workspace}/${each.value}")

  vars = {
    commit_hash = var.commit_hash
  }
}

# Use external data source to run the bash script to modify the claims
data "external" "modified_yaml" {
  for_each = data.template_file.claims
  program = ["bash", "${path.module}/modify-claims.sh"]

  query = {
    vault_id   = var.vault_id
    claim_yaml = each.value.rendered
  }
}

locals {
  updated_yaml_maps = {
    for key, claim in data.external.modified_yaml : key => yamldecode(claim.result.manifest)
  }

  updated_yaml_strings = {
    for key, yaml_map in local.updated_yaml_maps : key => yamlencode(yaml_map)
  }
}

resource "local_file" "output_yaml" {
  for_each = local.updated_yaml_strings
  filename = "${var.service_name}/configs/crossplane/${terraform.workspace}/${each.key}-manifest.yaml"
  content  = each.value
}

output "local_file" {
  value = local_file.output_yaml
}

data "kubectl_file_documents" "claims" {
  for_each = local.updated_yaml_strings
  content  = each.value
}

resource "kubectl_manifest" "claim" {
  for_each  = data.kubectl_file_documents.claims
  yaml_body = each.value.content
}
