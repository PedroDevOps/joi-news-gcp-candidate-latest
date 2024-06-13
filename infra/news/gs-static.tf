resource "google_storage_bucket" "news" {
  name          = "${var.project}-infra-static-pages"
  force_destroy = true

  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "error.html"
  }
}

resource "google_storage_bucket_iam_binding" "news" {
  bucket = google_storage_bucket.news.name
  role = "roles/storage.objectViewer"
  members = [
    "allUsers"
  ]
}