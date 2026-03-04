resource "libvirt_volume" "routing_openstack_disk" {
  name             = "routing_openstack_disk.qcow2"
  pool             = var.DEFAULT_DISK_POOL
  base_volume_name = var.BASE_VOLUME_NAME
  base_volume_pool = var.BASE_IMAGE_POOL
  format           = "qcow2"
  size             = 25 * 1024 * 1024 * 1024
}


# Define template for cloud_init
data "template_file" "user_data_os_routing" {
  vars = {
    hostname       = "os-routing"
    ssh_public_key = local.ssh_public_key
  }
  template = file("${path.module}/cloud-init-routing.cfg")
}

# Network configuration
data "template_file" "network_config_routing" {
  template = file("${path.module}/network-config-routing.cfg")
}

# Use CloudInit to add the instance
resource "libvirt_cloudinit_disk" "cloudinit_os_routing" {
  name           = "cloudinit_os_routing.iso"
  pool           = var.CLOUD_INIT_POOL
  user_data      = data.template_file.user_data_os_routing.rendered
  network_config = data.template_file.network_config_routing.rendered
}

# Define KVM domain to create
resource "libvirt_domain" "os-routing" {
  name   = "os-routing"
  memory = "2048"
  vcpu   = 2

  network_interface {
    network_name = "default"
    mac          = "52:54:00:22:be:05"
  }

  network_interface {
    network_name = "osnet"
  }

  disk {
    volume_id = libvirt_volume.routing_openstack_disk.id
  }

  cpu = {
    mode = "host-passthrough"
  }

  cloudinit = libvirt_cloudinit_disk.cloudinit_os_routing.id

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
