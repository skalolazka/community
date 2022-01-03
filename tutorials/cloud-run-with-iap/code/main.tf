# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

terraform {
  required_providers {
    google = ">= 3.40.0"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  secret_id = format("%s-secret", var.application_name)
}

data "google_project" "project" {
}

resource "google_project_service" "service-run" {
  service                    = "run.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "service-secretmanager" {
  service                    = "secretmanager.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "project_service" {
  service = "iap.googleapis.com"
}

resource "google_iap_brand" "project_brand" {
  support_email     = var.iap_support_email
  application_title = "Cloud IAP protected Application"
#  project           = google_project_service.project_service.project
}

resource "google_service_account" "service-account" {
  account_id   = var.service_account
  display_name = "Cloud Run Service Account"
}

resource "google_secret_manager_secret" "audience-secret" {
  secret_id = local.secret_id
  replication {
    automatic = true
  }
  depends_on = [
    google_project_service.service-secretmanager
  ]
}

resource "google_secret_manager_secret_iam_member" "audience-secret-iam" {
  secret_id = google_secret_manager_secret.audience-secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = format("serviceAccount:%s", google_service_account.service-account.email)
}

data "external" "audience-id" {
  program = [
    "gcloud",
    "compute",
    "backend-services",
    "describe",
    google_compute_backend_service.application-backend.name,
    "--global",
    "--format=json(id)"
  ]
}

resource "google_secret_manager_secret_version" "audience-secret-version" {
  secret = google_secret_manager_secret.audience-secret.id

  secret_data = format("/projects/%s/global/backendServices/%s", data.google_project.project.number, data.external.audience-id.result.id)
}

resource "google_cloud_run_service" "application" {
  name     = var.application_name
  location = var.region

  template {
    spec {
      containers {
        image = format("%s:%s", var.container, var.container_tag)
        env {
          name  = "SECRET"
          value = local.secret_id
        }
        env {
          name  = "PROJECT"
          value = var.project_id
        }
        ports {
          container_port = 8080
        }
      }
      container_concurrency = 10
      timeout_seconds       = 600
      service_account_name  = google_service_account.service-account.email
    }
    metadata {
      annotations = {
        "run.googleapis.com/ingress" = "internal-and-cloud-load-balancing"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true

  depends_on = [
    google_project_service.service-run,
    google_secret_manager_secret_iam_member.audience-secret-iam
  ]
}

# Allow unauthenticated requests (application protected by JWT tokens and IAP)
resource "google_cloud_run_service_iam_member" "application-allow-all" {
  location = google_cloud_run_service.application.location
  project  = google_cloud_run_service.application.project
  service  = google_cloud_run_service.application.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_compute_region_network_endpoint_group" "serverless-neg" {
  name                  = format("%s-neg", var.application_name)
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_service.application.name
  }
}

resource "google_compute_global_address" "application-global-ip" {
  name = format("%s-ip", var.application_name)
}

resource "google_compute_managed_ssl_certificate" "application-cert" {
  name = format("%s-cert", var.application_name)

  managed {
    domains = [format("%s.nip.io", google_compute_global_address.application-global-ip.address)]
  }
}

resource "google_compute_global_forwarding_rule" "application-global-fr" {
  name       = format("%s-fr", var.application_name)
  ip_address = google_compute_global_address.application-global-ip.address
  port_range = "443"
  target     = google_compute_target_https_proxy.application-proxy.self_link
}

resource "google_compute_target_https_proxy" "application-proxy" {
  name             = format("%s-proxy", var.application_name)
  url_map          = google_compute_url_map.application-url-map.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.application-cert.id]
}

resource "google_compute_url_map" "application-url-map" {
  name            = format("%s-urlmap", var.application_name)
  default_service = google_compute_backend_service.application-backend.self_link
}

resource "google_compute_backend_service" "application-backend" {
  name = format("%s-backend", var.application_name)

  backend {
    group = google_compute_region_network_endpoint_group.serverless-neg.id
  }

  iap {
    oauth2_client_id     = google_iap_client.application-client.client_id
    oauth2_client_secret = google_iap_client.application-client.secret
  }

  log_config {
    enable = true
  }
}

# If you get FAILED_PRECONDITION, it means the brand has been set as External.
# You'll need to create the client manually and specify it via iap_client_id
# and iap_client_secret parameters.
resource "google_iap_client" "application-client" {
  display_name = format("IAP-%s", var.application_name)
  brand        = google_iap_brand.project_brand.name # var.iap_brand
}