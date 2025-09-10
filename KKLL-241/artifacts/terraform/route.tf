/*resource "konnect_gateway_route" "eduGatewayRoute" {
  
  name          = "Anything"
 
  paths = [
    "/anything"
  ]
  
  strip_path = false
  control_plane_id = konnect_gateway_control_plane.eduCP1.id
  service = {
    id = konnect_gateway_service.eduGatewayService.id
  }
 
}*/
