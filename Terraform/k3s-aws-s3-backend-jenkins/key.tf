resource "tls_private_key" "ssh_key_aws" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  private_key_file = "private_key_aws.pem"
}

resource "local_file" "private_key_aws" {
  content  = tls_private_key.ssh_key_aws.private_key_pem
  filename = local.private_key_file
}

resource "aws_key_pair" "k3s-key" {
  key_name   = "k3s-key"
  public_key = tls_private_key.ssh_key_aws.public_key_openssh
}