resource "konnect_gateway_service" "httpbin" {
  name             = "HTTPBin"
  protocol         = "https"
  host             = "httpbin.konghq.com"
  port             = 443
  path             = "/"
  control_plane_id = konnect_gateway_control_plane.global_control_plane.id
}

resource "konnect_gateway_route" "anything" {
  methods = ["GET"]
  name    = "Anything"
  paths   = ["/anything"]
  strip_path = false

  control_plane_id = konnect_gateway_control_plane.global_control_plane.id
  service = {
    id = konnect_gateway_service.httpbin.id
  }
}

resource "konnect_gateway_plugin_rate_limiting" "my_rate_limiting_plugin" {
  enabled = true
  config = {
    minute = 5
    policy = "local"
  }

  protocols        = ["http", "https"]
  control_plane_id = konnect_gateway_control_plane.global_control_plane.id
  route = {
    id = konnect_gateway_route.anything.id
  }
}