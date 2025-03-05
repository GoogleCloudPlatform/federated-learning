resource "google_secret_manager_secret" "worker_parameter" {
  secret_id = format("fc-%s-%s", var.environment, var.parameter_name)
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "worker_parameter_value" {
  secret      = google_secret_manager_secret.worker_parameter.id
  secret_data = var.parameter_value
}
