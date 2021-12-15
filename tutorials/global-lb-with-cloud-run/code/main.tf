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

# Deploy Cloud Run
resource "google_cloud_run_service" "default" {
  for_each = toset(var.cloud_run_regions)
  project  = var.project_id
  name     = "${var.prefix}-${each.value}"
  location = each.value

  metadata {
    annotations = {
      # Do not allow requests coming from the internet, only ones that passed GCLB or coming from the internal network
      # Documentation here: https://cloud.google.com/run/docs/securing/ingress#yaml
      "run.googleapis.com/ingress" = "internal-and-cloud-load-balancing"
      "autoscaling.knative.dev/maxScale" = "101"
    }
  }

  template {
    spec {
      containers {
        # One could use environment variables here for the IP of the server
        # Out of the scope of this example
        image = var.cloud_run_image
        ports {
          container_port = 80
        }
      }
    }
  }
}

# Grant Cloud Run usage rights to someone who is authorized to access the end-point
resource "google_cloud_run_service_iam_member" "default" {
  for_each = toset(var.cloud_run_regions)
  project  = var.project_id
  location = each.value
  service  = "${var.prefix}-${each.value}" # same as the corresponting google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  # Replace with "user:YOUR_IAM_USER" for granting access only to yourself
  member   = var.cloud_run_invoker
  depends_on = [
    resource.google_cloud_run_service.default
  ]
}

# Serverless Network Endpoint Group (NEG) to be used in the load balancer backend
resource "google_compute_region_network_endpoint_group" "default" {
  for_each              = toset(var.cloud_run_regions)
  provider              = google-beta
  project               = var.project_id
  name                  = "${var.prefix}-neg-${each.value}"
  network_endpoint_type = "SERVERLESS"
  region                = each.value
  cloud_run {
    service = "${var.prefix}-${each.value}" # same as the corresponting google_cloud_run_service.default.name
  }
}

# Load balancer with the serverless NEG defined above
module "lb_serverless_negs" {
  source  = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version = "5.0.0"
  project = var.project_id
  name    = "${var.prefix}-lb"
  ssl     = false

  backends = {
    default = {
      description            = "Load balancer for Cloud Run"
      enable_cdn             = false
      custom_request_headers = null
      # Attach the Cloud Armor security policy defined below to limit access only from the specific IPs
      security_policy        = try(google_compute_security_policy.ip-limit[0].self_link, null)

      # Attach the NEGs defined above
      groups = [
        for neg in google_compute_region_network_endpoint_group.default: {group = neg.id}
      ]

      log_config = {
        enable      = true
        sample_rate = 1.0
      }
      iap_config = {
        enable               = false
        oauth2_client_id     = null
        oauth2_client_secret = null
      }
    }
  }
}


# Create a Cloud Armor security policy to limit access only from the specific IPs
# Documentation: https://cloud.google.com/armor/docs/configure-security-policies
resource "google_compute_security_policy" "ip-limit" {
  count   = length(var.source_ip_range_for_security_policy) == 0 ? 0 : 1
  project = var.project_id
  name    = "${var.prefix}-ip-limit"

  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = var.source_ip_range_for_security_policy
      }
    }
    description = "allow from specific IPs"
  }

  rule {
    action   = "deny(403)"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Deny access by default"
  }
}