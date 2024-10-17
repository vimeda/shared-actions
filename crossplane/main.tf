data "template_file" "claims" {
  for_each = fileset("../${var.service_name}/configs/crossplane/${terraform.workspace}", "*.yaml")
  template = file("../${var.service_name}/configs/crossplane/${terraform.workspace}/${each.value}")

  vars = {
    commit_hash = var.commit_hash
  }
}

#
# Use external data source to run the bash script to modify the claims
data "external" "modified_yaml" {
  for_each = data.template_file.claims
  program = ["bash", "${path.module}/modify-claims.sh"]

  query = {
    vault_id   = var.vault_id
    claim_yaml = each.value.rendered
  }
}

output "modified_yaml" {
  value = data.external.modified_yaml
}

# Locals for decoding the updated YAML from the external script output
locals {
  # Define the path to the directory containing YAML files
  yaml_dir = "${path.module}/tmp"  # Adjust this to your module's relative path
  yaml_files = fileset(local.yaml_dir, "*.yaml")  # Get all YAML files in the specified directory
}

# Parse the YAML content into Kubernetes documents using kubectl provider
data "kubectl_file_documents" "claims" {
  depends_on = [data.external.modified_yaml]  # Ensure this runs after the external data source
  for_each = data.external.modified_yaml
  content  = yamlencode(jsondecode(each.value.result.manifest))
}

output "kubectl_manifest" {
  value = data.kubectl_file_documents.claims
}

#Apply the Kubernetes manifests based on the modified claims
resource "kubectl_manifest" "claim" {
  count  = data.kubectl_file_documents.claims
  yaml_body = each.value.manifests.content[count.index]
}


