locals {
  gcr_url = "gcr.io/${var.project}"
}

# the dedicated service account that the compute instances will use
resource "google_service_account" "joi-news-instances" {
  account_id   = "${var.prefix}-compute"
  display_name = "${var.prefix} Service Account"
}

# grant the compute service account read access to GCR's underlying
# GCS bucket in order to be able to read our private Docker images
resource "google_storage_bucket_iam_binding" "bucket-policy" {
  bucket = "artifacts.${var.project}.appspot.com"
  role   = "roles/storage.objectViewer"
  members = [
    "serviceAccount:${google_service_account.joi-news-instances.email}",
  ]
}

data "google_compute_network" "default" {
  name = "vpc-${var.prefix}"
}

data "google_compute_subnetwork" "subnet" {
  name = "subnet-${var.prefix}"
}

### Front end server
data "template_file" "front_end_init_script" {
  template = file("${path.module}/provision-front_end.sh")
  vars = {
    docker_image = "${local.gcr_url}/front_end:latest"
    quote_service_url    = "http://${google_compute_instance.quotes.network_interface.0.access_config.0.nat_ip}:8082",
    newsfeed_service_url = "http://${google_compute_instance.newsfeed.network_interface.0.access_config.0.nat_ip}:8081",
    static_url           = "https://storage.googleapis.com/${google_storage_bucket.news.name}"
  }
}

resource "google_compute_instance" "front_end" {
  name         = "${var.prefix}-front-end"
  machine_type = var.machine_type
  zone         = "${var.region}-a"
  tags         = ["web"]

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-109-lts"
    }
  }

  metadata_startup_script = data.template_file.front_end_init_script.rendered

  network_interface {
    subnetwork = data.google_compute_subnetwork.subnet.self_link

    access_config {
      // Ephemeral IP
    }
  }
  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.joi-news-instances.email
    scopes = var.service_account_scopes
  }
}

# # Allow public access to the front-end server
resource "google_compute_firewall" "front_end" {
  name    = "front-end-firewall"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}
### end of front-end

### Quotes service deploy
data "template_file" "quotes_init_script" {
  template = file("${path.module}/provision-quotes.sh")
  vars = {
    docker_image = "${local.gcr_url}/quotes:latest"
  }
}

resource "google_compute_firewall" "quotes" {
  name    = "quotes-firewall"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["8082"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["quotes"]
}

resource "google_compute_instance" "quotes" {
  name         = "${var.prefix}-quotes"
  machine_type = var.machine_type
  zone         = "${var.region}-a"
  tags         = ["quotes"]

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-109-lts"
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.subnet.self_link

    access_config {
      // Ephemeral IP
    }
  }

  metadata_startup_script = data.template_file.quotes_init_script.rendered

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.joi-news-instances.email
    scopes = var.service_account_scopes
  }
}

### end of quotes service

### Newsfeed service deploy
data "template_file" "newsfeed_init_script" {
  template = file("${path.module}/provision-newsfeed.sh")
  vars = {
    docker_image = "${local.gcr_url}/newsfeed:latest"
  }
}

resource "google_compute_instance" "newsfeed" {
  name         = "${var.prefix}-newsfeed"
  machine_type = var.machine_type
  zone         = "${var.region}-a"
  tags         = [ "newsfeed"]

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-109-lts"
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.subnet.self_link

    access_config {
      // Ephemeral IP
    }
  }

 metadata_startup_script = data.template_file.newsfeed_init_script.rendered

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.joi-news-instances.email
    scopes = var.service_account_scopes
  }
}

resource "google_compute_firewall" "newsfeed" {
  name    = "newsfeed-firewall"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["8081"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["newsfeed"]
}

output "frontend_url" {
  value = "http://${google_compute_instance.front_end.network_interface.0.access_config.0.nat_ip}:8080"
}
