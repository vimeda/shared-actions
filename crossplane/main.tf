data "template_file" "claims" {
  for_each = fileset("${var.service_name}/configs/crossplane/${terraform.workspace}", "*.yaml")
  template = file(each.value)
}

locals {
  updated_yaml_maps = [
    for claim in data.template_file.claims : merge(
      yamldecode(claim.rendered),
      {
        spec = {
          parameters = merge(
            lookup(yamldecode(claim.rendered), "spec", {})["parameters"],
            {
              image_tag = var.commit_hash,
              vault_id  = var.vault_id,
            }
          )
        }
      }
    )
  ]

  updated_yaml = join("\n---\n", [ for yaml_map in local.updated_yaml_maps : yamlencode(yaml_map) ])
}

resource "local_file" "output_yaml" {
  filename = "${var.service_name}/configs/crossplane/${terraform.workspace}/combined.yaml"
  content  = local.updated_yaml
}

data "kubectl_file_documents" "claims" {
  content = local.updated_yaml
}

resource "kubectl_manifest" "claim" {
  for_each  = data.kubectl_file_documents.claims.manifests
  yaml_body = each.value
}

output "updated_claims" {
  value = local.updated_yaml
}
