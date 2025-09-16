terraform {
  required_providers {
    konnect = {
      source = "kong/konnect"
    }
  }
}

provider "konnect" {
  personal_access_token = "kpat_LYZoGuHclcigCbeAWwV5fDNnUrofG8qnF6QIOhmxE8GAdXhRp"
  server_url            = "https://us.api.konghq.com"
}