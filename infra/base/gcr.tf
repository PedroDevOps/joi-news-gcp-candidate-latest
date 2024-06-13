resource "google_container_registry" "registry" {
  project  = var.project
  location = "EU"
}

data "google_container_registry_repository" "repository" {
}

# grant default compute instance user ability to read from GCR
data "google_compute_default_service_account" "default" {}
resource "google_storage_bucket_iam_member" "viewer" {
  bucket = google_container_registry.registry.id
  role   = "roles/storage.admin"
  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

locals {
  gcr_url = data.google_container_registry_repository.repository.repository_url
}

resource "local_file" "gcr" {
  filename = "${path.module}/../gcr-url.txt"
  content  = local.gcr_url
}

output "repository_base_url" {
  value = local.gcr_url
}
