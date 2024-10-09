data "template_file" "claim" {
  template = file("templates/go-app.yaml")
}

locals {
  original_yaml = yamldecode(data.template_file.claim.rendered)

  updated_yaml_map = merge(
    local.original_yaml,
    {
      spec = {
        parameters = merge(
          local.original_yaml["spec"]["parameters"],
          {
            image_tag = var.image_tag
            vault_id = terraform.workspace == "staging" ? "errsir3kqd4gdjgaxliofyskey" : "37y43e5v2qd3iptgt7wgyk34ga" //TODO add this globally as secret
          }
        )
      }
    }
  )

  updated_yaml = yamlencode(local.updated_yaml_map)
}

data "template_file" "updated_claim" {
  template = local.updated_yaml
}

data "kubectl_file_documents" "claim" {
  content = data.template_file.updated_claim.rendered
}

resource "kubectl_manifest" "claim" {
  for_each  = data.kubectl_file_documents.claim.manifests
  yaml_body = each.value
}

output "updated_claim" {
  value = data.template_file.updated_claim.rendered
}
