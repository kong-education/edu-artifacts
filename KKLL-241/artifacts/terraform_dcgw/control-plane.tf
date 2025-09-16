resource "konnect_gateway_control_plane" "global_control_plane" {
  name          = "Global Control Plane"
  cluster_type  = "CLUSTER_TYPE_CONTROL_PLANE"
  cloud_gateway = true
  description   = "Global Multi Cloud Control plane"
  auth_type     = "pinned_client_certs"
  proxy_urls    = []
}



resource "konnect_cloud_gateway_configuration" "global_gateway_config" {
  api_access        = "private+public"
  control_plane_geo = "us"
  control_plane_id  = konnect_gateway_control_plane.global_control_plane.id

  dataplane_groups = [
    {
      provider = "aws"
      region   = "ap-south-2"
      autoscale = {
        configuration_data_plane_group_autoscale_autopilot = {
          kind     = "autopilot"
          base_rps = 10
          max_rps  = 100
        }
      }
      cloud_gateway_network_id = "00dbb722-3b9f-4fa1-8177-5073d4b2950a" 
    }    
  ]
  version = "3.9"
}