variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resource deployment"
  type        = string
}

variable "org_id" {
  description = "The organization ID"
  type        = string
}

output "secret_manager_ids" {
  value     = module.secret-manager.secret_ids
  sensitive = true
}

output "binary_auth_policy_id" {
  value = google_binary_authorization_policy.policy.id
}
