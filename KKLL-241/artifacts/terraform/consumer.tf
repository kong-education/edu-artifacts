/*resource "konnect_gateway_consumer" "kongedu" {
  control_plane_id = konnect_gateway_control_plane.eduCP1.id
  username   = "KongEdu"
 
}

resource "konnect_gateway_basic_auth" "KongEduAuth" {
  username = "KongEdu"
  password = "demo"

  consumer_id      = konnect_gateway_consumer.kongedu.id
  control_plane_id = konnect_gateway_control_plane.eduCP1.id
}*/

