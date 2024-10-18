terraform {
  required_version = ">= 1.0.0"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    local = {
      source = "hashicorp/local"
      version = "2.5.2"
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
  filename = "kubeconfig"
  content = var.kubeconfig
}

provider "kubectl" {
  load_config_file = true
  config_path = local_file.kubeconfig.filename
}

provider "kubernetes" {
  load_config_file = true
  config_path = local_file.kubeconfig.filename
}
