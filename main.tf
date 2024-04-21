# main.tf

// Enable required services for datadog
resource "google_project_service" "services" {
  for_each = toset([
    "cloudbilling.googleapis.com",
    "cloudasset.googleapis.com",
  ])
  project = var.project
  service = each.value

  # Conditionally set prevent_destroy based on variable
  lifecycle {
    prevent_destroy       = false
    create_before_destroy = true
  }
}

// Create Service Account for datadog
resource "google_service_account" "datadog_sa" {
  account_id   = "dataadog_service_account"
  display_name = "Datadog Service Account"
  project      = var.project
}

// Add necessary roles to datadog service account
resource "google_project_iam_member" "add_roles" {
  depends_on = [google_service_account.datadog_sa]
  for_each = toset([
    "roles/compute.viewer",
    "roles/monitoring.viewer",
    "roles/cloudasset.viewer",
    "roles/storage.admin",
    "roles/browser",
  ])
  role    = each.key
  member  = "serviceAccount:${google_service_account.datadog_sa.email}"
  project = var.project
}

# Use yamldecode to parse the YAML content
locals {
  datadog_manifest = yamldecode(file("${path.module}/datadog.yaml"))
}
# Apply the parsed YAML content
resource "kubernetes_manifest" "datadog_manifest" {
  manifest = local.datadog_manifest
}
