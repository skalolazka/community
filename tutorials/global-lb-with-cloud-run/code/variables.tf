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
  description = "Project ID to create resources into"
}

variable "prefix" {
  type        = string
  description = "Prefix for resource names"
}

variable "cloud_run_image" {
  type        = string
  description = "Image URL to deploy in Cloud Run"
  default     = "gcr.io/cloudrun/hello"
}

# Documentation here: https://cloud.google.com/armor/docs/security-policy-overview#ip-address-rules
variable "source_ip_range_for_security_policy" {
  type        = list(string)
  description = "Array of Cloud Armor security policy allowed IP ranges (put your IP as an array here)"
  default = []
}

# Documentation: https://cloud.google.com/run/docs/securing/managing-access#making_a_service_public
variable "cloud_run_invoker" {
  type        = string
  description = "IAM member authorized to access the end-point (for example, 'user:YOUR_IAM_USER' for only you or 'allUsers' for everyone)"
  default     = "allUsers"
}

variable "cloud_run_regions" {
  type        = list(string)
  description = "List of regions to deploy Cloud Run to"
}