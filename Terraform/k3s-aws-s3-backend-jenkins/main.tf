terraform {
  backend "s3" {
    bucket = "aws-terraform-infra-setup"
    key    = "dev/k3s/terraform.tfstate"
    region = "ap-south-1"
    dynamodb_table = "terraform-locking"
    encrypt = true
  }
}


resource "aws_instance" "k3s-master" {
  ami           = var.ami
  instance_type = var.type
  tags = {
    Name = "K3s-Master"
  }
  key_name               = aws_key_pair.k3s-key.key_name
  subnet_id              = aws_subnet.subnet-1.id
  vpc_security_group_ids = [aws_security_group.kubernetes-aws-sg.id]
  root_block_device {
    volume_size = var.root_block_device
  }

  provisioner "remote-exec" {

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = var.ssh_user
      private_key = tls_private_key.ssh_key_aws.private_key_pem
    }

    inline = [
      "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=\"v1.25.5+k3s1\" sh -s - server --token=${var.token} --cluster-init --cluster-cidr ${var.cluster-pod-cidr} --service-cidr ${var.cluster-service-cidr} --tls-san ${self.public_ip}",

    ]
  }

}

resource "aws_instance" "k3s-worker1-aws" {
  ami           = var.ami
  instance_type = var.type
  tags = {
    Name = "K3s-Worker1"
  }
  key_name               = aws_key_pair.k3s-key.key_name
  subnet_id              = aws_subnet.subnet-1.id
  vpc_security_group_ids = [aws_security_group.kubernetes-aws-sg.id]
  root_block_device {
    volume_size = var.root_block_device
  }

  provisioner "remote-exec" {

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = var.ssh_user
      private_key = tls_private_key.ssh_key_aws.private_key_pem
    }

    inline = [
      "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=\"v1.25.5+k3s1\" sh -s - agent --server https://${aws_instance.k3s-master.private_ip}:6443 --token=${var.token}"

    ]
  }

}

resource "aws_instance" "k3s-worker2-aws" {
  ami           = var.ami
  instance_type = var.type
  tags = {
    Name = "K3s-Worker2"
  }
  key_name               = aws_key_pair.k3s-key.key_name
  subnet_id              = aws_subnet.subnet-1.id
  vpc_security_group_ids = [aws_security_group.kubernetes-aws-sg.id]
  root_block_device {
    volume_size = var.root_block_device
  }

  provisioner "remote-exec" {

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = var.ssh_user
      private_key = tls_private_key.ssh_key_aws.private_key_pem
    }

    inline = [
      "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=\"v1.25.5+k3s1\" sh -s - agent --server https://${aws_instance.k3s-master.private_ip}:6443 --token=${var.token}"

    ]
  }

}

resource "aws_instance" "k3s-worker3-aws" {
  ami           = var.ami
  instance_type = var.type
  tags = {
    Name = "K3s-Worker3"
  }
  key_name               = aws_key_pair.k3s-key.key_name
  subnet_id              = aws_subnet.subnet-1.id
  vpc_security_group_ids = [aws_security_group.kubernetes-aws-sg.id]
  root_block_device {
    volume_size = var.root_block_device
  }

  provisioner "remote-exec" {

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = var.ssh_user
      private_key = tls_private_key.ssh_key_aws.private_key_pem
    }

    inline = [
      "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=\"v1.25.5+k3s1\" sh -s - agent --server https://${aws_instance.k3s-master.private_ip}:6443 --token=${var.token}"

    ]
  }

}