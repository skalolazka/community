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

variable "project_id" {
  type        = string
  description = "Project ID to deploy in"
}

variable "region" {
  type        = string
  description = "Region to deploy in"
  default     = "europe-west1"
}

variable "application_name" {
  type        = string
  description = "Application name"
  default     = "springboot-iap"
}

variable "service_account" {
  type        = string
  description = "Service account to create for Cloud Run function"
  default     = "springboot-iap"
}

variable "container" {
  type        = string
  description = "GCR address for Turbo Project Factory container (eg. eu.gcr.io/YOUR-PROJECT/springboot-iap)"
}

variable "container_tag" {
  type        = string
  description = "Container tag"
  default     = "latest"
}

# To get brand: gcloud alpha iap oauth-brands list 
# (looks like: projects/909415680861/brands/909415680861)
# If you don't have any brands, set them up via console: API & Services > OAuth Consent Screen
#variable "iap_brand" {
#  type        = string
#  description = "IAP brand"
#}

variable "iap_support_email" {
  type        = string
  description = "IAP OAuth consent screen support email (suitable!)"
}

