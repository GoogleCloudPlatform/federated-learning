variable "environment" {
  type        = string
  description = "Description for the environment, e.g. dev, staging, production"
}

variable "parameter_name" {
  type        = string
  description = "Name of the parameter."
}

variable "parameter_value" {
  type        = string
  description = "Value of the parameter."
}
