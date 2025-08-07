cat > foo-service-dynamic.yaml << EOF
_format_version: "3.0"
services:
- connect_timeout: 60000
  host: $1
  name: $2
  port: $3
EOF
deck sync -s foo-service.yaml

$ HOST="example.com"
$ NAME="foo"
$ PORT=443

