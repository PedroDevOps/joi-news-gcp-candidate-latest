# Setup our GCP provider
variable "region" {
  default = "us-central1"
}

variable "project" {
}

provider "google" {
  project     = var.project
  region      = var.region
  credentials = "../.interviewee-creds.json"
}

terraform {
  backend "gcs" {
    prefix      = "news"
    credentials = "../.interviewee-creds.json"
  }
}
