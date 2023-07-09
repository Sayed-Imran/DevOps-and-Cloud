output "name" {
  value = aws_instance.k3s-master.tags.Name
}

output "public_ip" {
  value = aws_instance.k3s-master.public_ip
}

output "private_ip" {
  value = aws_instance.k3s-master.private_ip
}

output "instance_id" {
  value = aws_instance.k3s-master.id
}

output "instance_type" {
  value = aws_instance.k3s-master.instance_type
}

output "sg-name" {
  value = aws_security_group.kubernetes-aws-sg.name
}