ui = false
api_addr = "http://openbao:8200"

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}

storage "pebbledb" {
  path = "/openbao/file/pebbledb"
}

# The trusted Docker host/root account is the local source of trust for
# auto-unseal. Keep this key outside the OpenBao data directory.
seal "static" {
  current_key_id = "akaunting-nfse-static-v1"
  current_key    = "file:///run/secrets/openbao_static_seal_key"
}
