
/*resource "konnect_gateway_control_plane" "eduCPGroup" {
  name         = "Terraform Control Plane Group"
  description  = "This is a sample CP group created for education"
  cluster_type = "CLUSTER_TYPE_CONTROL_PLANE_GROUP"
  auth_type    = "pinned_client_certs"

  proxy_urls = []
}


resource "konnect_gateway_control_plane_membership" "eduCPGroupMember" 
{
  id = konnect_gateway_control_plane.eduCPGroup.id
  members = [
    { id = konnect_gateway_control_plane.eduCP1.id }
   
  ]
}*/