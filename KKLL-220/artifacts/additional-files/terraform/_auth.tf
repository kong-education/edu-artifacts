# Configure the provider to use your Kong Konnect account
terraform {
  required_providers {
    konnect = {
      source  = "kong/konnect"
      version = "2.7.1"
    }
  }
}

provider "konnect" {
  personal_access_token = "kpat"
  server_url            = "https://us.api.konghq.com"
}