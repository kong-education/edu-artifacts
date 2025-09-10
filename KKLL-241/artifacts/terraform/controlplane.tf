resource "konnect_gateway_control_plane" "eduCP1" {
  name         = "teameduCP1"
  description  = "CP1 created for KKLL-241 course"
  cluster_type = "CLUSTER_TYPE_HYBRID"
  auth_type    = "pinned_client_certs"
  
  proxy_urls = [
    {
      host     = "localhost",
      port     = 8000,
      protocol = "http"
    }
  ]
}



