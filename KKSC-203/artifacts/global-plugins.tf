resource "konnect_gateway_plugin_rate_limiting_advanced" "global_rate_limiting_advanced" {
 enabled = true

 config = {
   limit = [10]
   window_size = [60]
   identifier = "consumer"
   sync_rate = -1
   namespace = "example_namespace"
   strategy = "local"
   hide_client_headers = false
 }

 control_plane_id = konnect_gateway_control_plane.kongair_global_cp.id
}