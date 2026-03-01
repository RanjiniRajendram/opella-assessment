variable "environment" {
  type        = string
  description = "Logical name for the environment (dev/qa/prod)"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "project" {
  type        = string
  description = "Project for which the resources are created"
}
