terraform {
  required_providers {
    konnect = {
      source  = "kong/konnect"
      version = "1.0.0"
    }
  }
}

provider "konnect" {
  system_account_access_token = var.system_account_access_token
  server_url                  = var.server_url
}

# Control Planes

resource "konnect_gateway_control_plane" "kongair_internal_cp" {
  name         = "KongAir_Internal"
  description  = "CP for the Kong Air Internal API configurations"
  cluster_type = "CLUSTER_TYPE_CONTROL_PLANE"
  auth_type    = "pki_client_certs"

  labels = {
    environment  = var.environment
    team = "kong-air-internal"
    generated_by = "terraform"
  }
}

resource "konnect_gateway_control_plane" "kongair_external_cp" {
  name         = "KongAir_External"
  description  = "CP for the Kong Air External API configurations"
  cluster_type = "CLUSTER_TYPE_CONTROL_PLANE"
  auth_type    = "pki_client_certs"

  labels = {
    environment  = var.environment
    team = "kong-air-external"
    generated_by = "terraform"
  }
}

resource "konnect_gateway_control_plane" "kongair_global_cp" {
  name         = "KongAir_Global"
  description  = "CP for Global Configurations"
  cluster_type = "CLUSTER_TYPE_CONTROL_PLANE"
  auth_type    = "pki_client_certs"

  labels = {
    environment  = var.environment
    team = "platform"
    generated_by = "terraform"
  }
}

# Control Plane Groups

resource "konnect_gateway_control_plane" "kongair_internal_cp_group" {
  name         = "KongAir_Internal_CP_Group"
  description  = "Control Plane group for configuring internal Gateways"
  cluster_type = "CLUSTER_TYPE_CONTROL_PLANE_GROUP"
  auth_type    = "pki_client_certs"

  labels = {
    generated_by = "terraform"
    environment  = var.environment
  }
}

resource "konnect_gateway_control_plane" "kongair_external_cp_group" {
  name         = "KongAir_External_CP_Group"
  description  = "Control Plane group for configuring external Gateways"
  cluster_type = "CLUSTER_TYPE_CONTROL_PLANE_GROUP"
  auth_type    = "pki_client_certs"

  labels = {
    generated_by = "terraform"
    environment  = var.environment
  }
}

# Control Plane Memberships

resource "konnect_gateway_control_plane_membership" "kongair_internal_cp_group_membership" {
  id = konnect_gateway_control_plane.kongair_internal_cp_group.id
  members = [
    {
        id = konnect_gateway_control_plane.kongair_internal_cp.id
    },
    {
        id = konnect_gateway_control_plane.kongair_global_cp.id
    }
  ]
}

resource "konnect_gateway_control_plane_membership" "kongair_external_cp_group_membership" {
  id = konnect_gateway_control_plane.kongair_external_cp_group.id
  members = [
    {
        id = konnect_gateway_control_plane.kongair_external_cp.id
    },
    {
        id = konnect_gateway_control_plane.kongair_global_cp.id
    }
  ]
}

# Teams

# Internal Developers Team
# The internal developers team is responsible for managing the internal control plane configurations.

resource "konnect_team" "kong_air_internal_devs" {
  description = "Allow managing the internal control plane configurations"
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
# The internal viewers team is responsible for monitoring the internal control plane configurations.

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
# The external developers team is responsible for managing the external control plane configurations.

resource "konnect_team" "kong_air_external_devs" {
  description = "Allow read-only access to all entities in the external control plane"
  name        = "Kong Air External Developers"
}

resource "konnect_team_role" "kong_air_external_cp_admin" {
  entity_id        = konnect_gateway_control_plane.kongair_external_cp.id
  entity_region    = "us"
  entity_type_name = "Control Planes"
  role_name        = "Admin"
  team_id          = konnect_team.kong_air_external_devs.id
}

# External Viewers Team
# The external viewers team is responsible for monitoring the external control plane configurations.

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
  description = "Allow managing all entities in the global, internal and external control planes"
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








