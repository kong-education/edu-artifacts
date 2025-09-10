terraform {
  required_providers {
    konnect = {
      source = "kong/konnect"
    }
  }
}

provider "konnect" {
  personal_access_token = "kpat_7eJsVCVSxlAKaIp5grTjV0iShbLoAfjGfDkWWTTX7eaQkgt9Z"
  server_url            = "https://us.api.konghq.com"
}