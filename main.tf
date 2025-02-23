terraform {
  required_version = ">= 1.0.0"
}

# Secret Manager for storing sensitive data
module "secret-manager" {
  source     = "terraform-google-modules/secret-manager/google"
  version    = "~> 0.1"
  project_id = var.project_id
  secrets = [
    {
      name                  = "db-password"
      automatic_replication = true
      secret_data           = random_password.db_password.result
    },
    {
      name                  = "api-key"
      automatic_replication = true
      secret_data           = random_password.api_key.result
    }
  ]
}

# Generate random passwords
resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "random_password" "api_key" {
  length  = 32
  special = true
}

# IAM bindings for service accounts
resource "google_service_account_iam_binding" "workload_identity" {
  service_account_id = data.terraform_remote_state.compute.outputs.gke_service_account
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[default/default]"
  ]
}

# Binary Authorization policy
resource "google_binary_authorization_policy" "policy" {
  project = var.project_id

  default_admission_rule {
    evaluation_mode  = "ALWAYS_ALLOW"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
  }

  cluster_admission_rules {
    cluster          = data.terraform_remote_state.compute.outputs.cluster_name
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
  }
}

# Security Command Center settings
resource "google_scc_source" "custom_source" {
  display_name = "Custom Security Source"
  organization = var.org_id
  description  = "Custom security source for vulnerability management"
}

data "terraform_remote_state" "compute" {
  backend = "gcs"
  config = {
    bucket = "tf-state-gcp-kubernetes"
    prefix = "terraform/state/compute"
  }
}

variable "org_id" {
  description = "The organization ID"
  type        = string
}
