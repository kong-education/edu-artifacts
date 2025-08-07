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