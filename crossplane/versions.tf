terraform {
  required_version = ">= 1.0.0"

  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0.0"
    }
    local = {
      source  = "hashicorp/local"
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
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  load_config_file       = false
}

