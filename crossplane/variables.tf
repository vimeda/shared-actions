variable "commit_hash" {
  description = "git commit hash, which will be used to tag the docker image"
  type = string
}

variable "cluster_name" {
  description = "name of the eks cluster"
  type = string
}

variable "service_name" {
  description = "name of the service to deploy"
  type = string
}

variable "vault_id" {
  description = "1password vault id"
  type = string
}
