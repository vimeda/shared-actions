terraform {
  required_version = ">= 1.0.0"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
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

provider "aws" {
  region = "eu-central-1"
}

provider "kubectl" {
  config_path       = "/home/runner/config"
  load_config_file  = true
  apply_retry_count = 15
}