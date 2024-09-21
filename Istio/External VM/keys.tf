# TODO: Add the logic for creating the private key for the VM and adding to metadata

resource "tls_private_key" "ssh_key_gcp" {
  algorithm = "RSA"
  rsa_bits  = 4096
  
}

locals {
  private_key_file = "private_key_gcp.pem"
}

resource "local_file" "private_key_gcp" {
  content  = tls_private_key.ssh_key_gcp.private_key_pem
  filename = local.private_key_file
}