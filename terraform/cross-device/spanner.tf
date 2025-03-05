# Create the Spanner instance
resource "google_spanner_instance" "odp_spanner" {
  name             = var.spanner_instance_name
  config           = "regional-${var.region}"
  display_name     = "Federated Compute Database"
  processing_units = var.spanner_processing_units == null ? var.spanner_nodes * 1000 : var.spanner_processing_units
  force_destroy    = true
  project          = data.google_project.project.project_id

  labels = {
    environment = var.environment
    purpose     = "federated-compute"
  }

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      processing_units,
      labels,
      display_name,
      config,
      force_destroy,
    ]
  }
}

locals {
  # Read all .sdl files from the schema directory
  schema_files = fileset("${path.module}/spanner/schema", "*.sdl")

  # Read each file's content
  file_contents = {
    for file in local.schema_files :
    file => file("${path.module}/spanner/schema/${file}")
  }

  # Process the content of each file to extract DDL statements
  raw_statements = flatten([
    for content in values(local.file_contents) : split("CREATE", content)
  ])

  # Clean up and format statements
  ddl_statements = [
    for stmt in local.raw_statements :
    "CREATE${stmt}"
    if trimspace(stmt) != ""
  ]
}

# Create the Spanner database with deletion protection disabled
resource "google_spanner_database" "odp_db" {
  instance            = google_spanner_instance.odp_spanner.name
  name                = var.spanner_database_name
  project             = data.google_project.project.project_id
  deletion_protection = false

  ddl = [
    for stmt in local.ddl_statements :
    replace(
      replace(
        trimspace(stmt),
        "\n",
        " "
      ),
      ",)",
      ")"
    )
  ]

  lifecycle {
    ignore_changes = [
      deletion_protection
    ]
  }

  depends_on = [
    google_spanner_instance.odp_spanner
  ]
}

# Debug outputs to verify schema loading
output "loaded_schema_files" {
  value = local.schema_files
}

output "file_contents" {
  value = local.file_contents
}

output "ddl_statements" {
  value = local.ddl_statements
}
