output "name" {
  value = aws_instance.k3s-master-aws.tags.Name
}

output "public_ip" {
  value = aws_instance.k3s-master-aws.public_ip
}

output "private_ip" {
  value = aws_instance.k3s-master-aws.private_ip
}

output "instance_id" {
  value = aws_instance.k3s-master-aws.id
}

output "instance_type" {
  value = aws_instance.k3s-master-aws.instance_type
}

output "sg-name" {
  value = aws_security_group.kubernetes-aws-sg.name
}