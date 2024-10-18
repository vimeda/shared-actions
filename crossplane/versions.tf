terraform {
  required_version = ">= 1.0.0"

  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "4.64.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
  }
  backend "s3" {
    region = "eu-central-1"
    bucket = "terraform-eks"
    key    = "crossplane/gdpr-deleter-srv"
  }
}

variable "kubeconfig" {}

resource "local_file" "kubeconfig" {
  content  = var.kubeconfig
  filename = "/tmp/kubeconfig.yaml"
}

provider "kubectl" {
  load_config_file = false
}
