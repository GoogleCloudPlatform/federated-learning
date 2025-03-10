module "encryption_key_service_a_base_url" {
  source          = "./secretmanager"
  environment     = var.environment
  parameter_name  = "ENCRYPTION_KEY_SERVICE_A_BASE_URL"
  parameter_value = var.encryption_key_service_a_base_url
}

module "encryption_key_service_b_base_url" {
  source          = "./secretmanager"
  environment     = var.environment
  parameter_name  = "ENCRYPTION_KEY_SERVICE_B_BASE_URL"
  parameter_value = var.encryption_key_service_b_base_url
}

module "encryption_key_service_a_cloudfunction_url" {
  source          = "./secretmanager"
  environment     = var.environment
  parameter_name  = "ENCRYPTION_KEY_SERVICE_A_CLOUDFUNCTION_URL"
  parameter_value = var.encryption_key_service_a_cloudfunction_url
}

module "encryption_key_service_b_cloudfunction_url" {
  source          = "./secretmanager"
  environment     = var.environment
  parameter_name  = "ENCRYPTION_KEY_SERVICE_B_CLOUDFUNCTION_URL"
  parameter_value = var.encryption_key_service_b_cloudfunction_url
}

module "wip_provider_a" {
  source          = "./secretmanager"
  environment     = var.environment
  parameter_name  = "WIP_PROVIDER_A"
  parameter_value = var.wip_provider_a
}

module "wip_provider_b" {
  source          = "./secretmanager"
  environment     = var.environment
  parameter_name  = "WIP_PROVIDER_B"
  parameter_value = var.wip_provider_b
}

module "service_account_a" {
  source          = "./secretmanager"
  environment     = var.environment
  parameter_name  = "SERVICE_ACCOUNT_A"
  parameter_value = var.service_account_a
}

module "service_account_b" {
  source          = "./secretmanager"
  environment     = var.environment
  parameter_name  = "SERVICE_ACCOUNT_B"
  parameter_value = var.service_account_b
}

module "model_updater_pubsub_subscription" {
  source          = "./secretmanager"
  environment     = var.environment
  parameter_name  = "MODEL_UPDATER_PUBSUB_SUBSCRIPTION"
  parameter_value = module.pubsub["modelupdater_topic"].subscription_names[0]
}

module "model_updater_pubsub_topic" {
  source          = "./secretmanager"
  environment     = var.environment
  parameter_name  = "MODEL_UPDATER_PUBSUB_TOPIC"
  parameter_value = module.pubsub["modelupdater_topic"].topic
}

module "aggregator_pubsub_subscription" {
  source          = "./secretmanager"
  environment     = var.environment
  parameter_name  = "AGGREGATOR_PUBSUB_SUBSCRIPTION"
  parameter_value = module.pubsub["aggregator_topic"].subscription_names[0]
}

module "aggregator_pubsub_topic" {
  source          = "./secretmanager"
  environment     = var.environment
  parameter_name  = "AGGREGATOR_PUBSUB_TOPIC"
  parameter_value = module.pubsub["aggregator_topic"].topic
}

module "aggregator_notifications_pubsub_subscription" {
  source          = "./secretmanager"
  environment     = var.environment
  parameter_name  = "AGGREGATOR_NOTIF_PUBSUB_SUBSCRIPTION"
  parameter_value = module.pubsub["aggregator_notifications_topic"].subscription_names[0]
}

module "aggregator_notifications_pubsub_topic" {
  source          = "./secretmanager"
  environment     = var.environment
  parameter_name  = "AGGREGATOR_NOTIF_PUBSUB_TOPIC"
  parameter_value = module.pubsub["aggregator_notifications_topic"].topic
}
