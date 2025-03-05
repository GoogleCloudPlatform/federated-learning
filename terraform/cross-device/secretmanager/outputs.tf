output "secret_name" {
  description = "Name of created secret"
  value       = google_secret_manager_secret.worker_parameter.id
}
