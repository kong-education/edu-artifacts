// variables.tf

variable "system_account_access_token" {
  description = "The system account token to use for API requests"
  type        = string
}

variable "server_url" {
  description = "The URL of the Konnect server to connect to"
  type        = string
}

variable "environment" {
  description = "The environment resources will be associated with"
  type        = string
}
