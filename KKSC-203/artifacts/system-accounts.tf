locals {
  days_to_hours   = 365 * 24 // 1 year
  expiration_date = timeadd(formatdate("YYYY-MM-DD'T'HH:mm:ssZ", timestamp()), "${local.days_to_hours}h")
}

# System Account for Kong Air Internal Devs
# This system account will be assigned to the Kong Air Internal Devs team
# and will have an access token that expires in 1 year

resource "konnect_system_account" "sa_kong_air_internal_dev" {
  name            = "sa_kong_air_internal_dev"
  description     = "System account for Kong Air Internal Devs"
  konnect_managed = false

}

resource "konnect_system_account_team" "sa_kong_air_internal_dev_team" {
  account_id = konnect_system_account.sa_kong_air_internal_dev.id

  team_id = konnect_team.kong_air_internal_devs.id
}

resource "konnect_system_account_access_token" "sa_kong_air_internal_dev_token" {

  name       = "sa_kong_air_internal_dev_token"
  expires_at = local.expiration_date
  account_id = konnect_system_account.sa_kong_air_internal_dev.id

}

# System Account for Kong Air External Devs
# This system account will be assigned to the Kong Air External Devs team
# and will have an access token that expires in 1 year

resource "konnect_system_account" "sa_kong_air_external_dev" {
  name            = "sa_kong_air_external_dev"
  description     = "System account for Kong Air External Devs"
  konnect_managed = false

}

resource "konnect_system_account_team" "sa_kong_air_external_dev_team" {
  account_id = konnect_system_account.sa_kong_air_external_dev.id

  team_id = konnect_team.kong_air_external_devs.id
}

resource "konnect_system_account_access_token" "sa_kong_air_external_dev_token" {

  name       = "sa_kong_air_external_dev_token"
  expires_at = local.expiration_date
  account_id = konnect_system_account.sa_kong_air_external_dev.id

}

# System Account for Platform Admins Team
# This system account will be assigned to the Platform Admins team
# and will have an access token that expires in 1 year

resource "konnect_system_account" "sa_platform_admin" {
  name            = "sa_platform_admin"
  description     = "System account for Platform Admins team"
  konnect_managed = false

}

resource "konnect_system_account_team" "sa_platform_team" {
  account_id = konnect_system_account.sa_platform_admin.id

  team_id = konnect_team.platform_admins.id
}

resource "konnect_system_account_access_token" "sa_platform_token" {

  name       = "sa_platform_admin_token"
  expires_at = local.expiration_date
  account_id = konnect_system_account.sa_platform_admin.id

}

# System Account for Platform Viewers Team
# This system account will be assigned to the Platform Viewers team
# and will have an access token that expires in 1 year

resource "konnect_system_account" "sa_platform_viewer" {
  name            = "sa_platform_viewer"
  description     = "System account for Platform Viewers team"
  konnect_managed = false

}

resource "konnect_system_account_team" "sa_platform_viewer_team" {
  account_id = konnect_system_account.sa_platform_viewer.id

  team_id = konnect_team.platform_viewers.id
}

resource "konnect_system_account_access_token" "sa_platform_viewer_token" {

  name       = "sa_platform_viewer_token"
  expires_at = local.expiration_date
  account_id = konnect_system_account.sa_platform_viewer.id

}
