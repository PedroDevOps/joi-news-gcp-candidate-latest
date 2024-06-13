variable "machine_type" {
  default = "f1-micro"
}
variable "docker_image_tag" {
  default = "latest"
}
variable "prefix" {
  default = "news4321"
}

variable "service_account_scopes" {
  description = "List of scopes for the instances' service account"
  type        = list(string)

  default = [
    "https://www.googleapis.com/auth/userinfo.email",
    "https://www.googleapis.com/auth/compute.readonly",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/source.read_only",
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/cloud-platform.read-only"
  ]
}
