resource "null_resource" "install_istio" {
  depends_on = [google_container_cluster.primary]

  provisioner "local-exec" {
    command = <<EOT
      gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${google_container_cluster.primary.location} --project ${var.project_id}
      istioctl install --set values.pilot.env.PILOT_ENABLE_WORKLOAD_ENTRY_AUTOREGISTRATION=true --set values.pilot.env.PILOT_ENABLE_WORKLOAD_ENTRY_HEALTHCHECKS=true
      GATEWAY_IP=$(kubectl get svc -n istio-system istio-ingressgateway -ojsonpath='{.status.loadBalancer.ingress[0].ip}')
      istioctl x workload entry configure --file ratings-workloadgroup.yaml --output vm_files --autoregister
    EOT
  }
}

resource "null_resource" "configure_vm" {
  depends_on = [ null_resource.install_istio ]
  
  provisioner "file" {
    source      = "vm_files/"
    destination = "/home/${var.vm_user}/"

    connection {
        type        = "ssh"
        host        = google_compute_instance.vm.network_interface.0.access_config.0.nat_ip
        user        = var.vm_user
        private_key = tls_private_key.ssh_key_gcp.private_key_pem
    }
  }

  provisioner "remote-exec" {
  
    connection {
        type        = "ssh"
        host        = google_compute_instance.vm.network_interface.0.access_config.0.nat_ip
        user        = var.vm_user
        private_key = tls_private_key.ssh_key_gcp.private_key_pem
    }
    inline = [ 
        "sudo apt-get update",
        "curl -LO https://storage.googleapis.com/istio-release/releases/1.23.2/deb/istio-sidecar.deb",
        "sudo dpkg -i istio-sidecar.deb",
        "sudo mkdir -p /etc/certs",
        "sudo cp /home${var.vm_user}/root-cert.pem /etc/certs/root-cert.pem",
        "sudo  mkdir -p /var/run/secrets/tokens",
        "sudo cp /home/${var.var.vm_user}/istio-token /var/run/secrets/tokens/istio-token",
        "sudo cp ${var.vm_user}/cluster.env /var/lib/istio/envoy/cluster.env",
        "sudo cp /home${var.vm_user}/mesh.yaml /etc/istio/config/mesh",
        "sudo sh -c 'cat $(eval echo ~$SUDO_USER)/hosts >> /etc/hosts'",
        "sudo mkdir -p /etc/istio/proxy",
        "sudo chown -R istio-proxy /var/lib/istio /etc/certs /etc/istio/proxy /etc/istio/config /var/run/secrets /etc/certs/root-cert.pem",
        "sudo systemctl restart istio",
        
     ]
  }
}

