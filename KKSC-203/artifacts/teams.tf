# Internal Developer Team
# The internal developers team is responsible for managing the internal control plane configuration

resource "konnect_team" "kong_air_internal_devs" {
  description = "Allow managing the internal control plane configuration."
  name        = "Kong Air Internal Developers"
}

resource "konnect_team_role" "kong_air_internal_cp_admin" {
  entity_id        = konnect_gateway_control_plane.kongair_internal_cp.id
  entity_region    = "us"
  entity_type_name = "Control Planes"
  role_name        = "Admin"
  team_id          = konnect_team.kong_air_internal_devs.id
}

# Internal Viewers Team
# The internal viewers team is responsible for monitoring the internal control plane configuration and will have read only access to the Internal Control Plane.

resource "konnect_team" "kong_air_internal_viewers" {
  description = "Allow read-only access to all entities in the internal control plane"
  name        = "Kong Air Internal Viewers"
}

resource "konnect_team_role" "kong_air_internal_cp_viewer" {
  entity_id        = konnect_gateway_control_plane.kongair_internal_cp.id
  entity_region    = "us"
  entity_type_name = "Control Planes"
  role_name        = "Viewer"
  team_id          = konnect_team.kong_air_internal_viewers.id
}

# External Developers Team
# The external developers team is responsible for managing the external control plane configuration

resource "konnect_team" "kong_air_external_devs" {
  description = "Allow managing the external control plane configuration."
  name        = "Kong Air Internal Developers"
}

resource "konnect_team_role" "kong_air_external_cp_admin" {
  entity_id        = konnect_gateway_control_plane.kongair_external_cp.id
  entity_region    = "us"
  entity_type_name = "Control Planes"
  role_name        = "Admin"
  team_id          = konnect_team.kong_air_external_devs.id
}

# External Viewers Team
# The external viewers team is responsible for monitoring the internal control plane configuration

resource "konnect_team" "kong_air_external_viewers" {
  description = "Allow read-only access to all entities in the external control plane"
  name        = "Kong Air External Viewers"
}

resource "konnect_team_role" "kong_air_external_cp_viewer" {
  entity_id        = konnect_gateway_control_plane.kongair_external_cp.id
  entity_region    = "us"
  entity_type_name = "Control Planes"
  role_name        = "Viewer"
  team_id          = konnect_team.kong_air_external_viewers.id
}

# Platform Admins Team
# The platform admins team is responsible for managing all entities in the global,
# internal and external control planes.

resource "konnect_team" "platform_admins" {
  description = "Allow managing entities in the global, internal and external control planes"
  name        = "Platform Admins"
}

resource "konnect_team_role" "platform_admins_global_cp_admin" {
  entity_id        = konnect_gateway_control_plane.kongair_global_cp.id
  entity_region    = "us"
  entity_type_name = "Control Planes"
  role_name        = "Admin"
  team_id          = konnect_team.platform_admins.id
}

resource "konnect_team_role" "platform_admins_internal_cp_admin" {
  entity_id        = konnect_gateway_control_plane.kongair_internal_cp.id
  entity_region    = "us"
  entity_type_name = "Control Planes"
  role_name        = "Admin"
  team_id          = konnect_team.platform_admins.id
}

resource "konnect_team_role" "platform_admins_external_cp_admin" {
  entity_id        = konnect_gateway_control_plane.kongair_external_cp.id
  entity_region    = "us"
  entity_type_name = "Control Planes"
  role_name        = "Admin"
  team_id          = konnect_team.platform_admins.id
}

# Platform Viewers Team
# The platform viewers team is responsible for monitoring all entities in the global,
# internal and external control planes.

resource "konnect_team" "platform_viewers" {
  description = "Allow read-only access to all entities in the global, internal and external control planes"
  name        = "Platform Viewers"
}

resource "konnect_team_role" "platform_viewers_global_cp_viewer" {
  entity_id        = konnect_gateway_control_plane.kongair_global_cp.id
  entity_region    = "us"
  entity_type_name = "Control Planes"
  role_name        = "Viewer"
  team_id          = konnect_team.platform_viewers.id
}

resource "konnect_team_role" "platform_viewers_internal_cp_viewer" {
  entity_id        = konnect_gateway_control_plane.kongair_internal_cp.id
  entity_region    = "us"
  entity_type_name = "Control Planes"
  role_name        = "Viewer"
  team_id          = konnect_team.platform_viewers.id
}

resource "konnect_team_role" "platform_viewers_external_cp_viewer" {
  entity_id        = konnect_gateway_control_plane.kongair_external_cp.id
  entity_region    = "us"
  entity_type_name = "Control Planes"
  role_name        = "Viewer"
  team_id          = konnect_team.platform_viewers.id
}