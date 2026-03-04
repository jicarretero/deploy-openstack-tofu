resource "libvirt_volume" "compute_openstack_disk" {
  count            = var.COMPUTES_COUNT
  pool             = var.DEFAULT_DISK_POOL
  base_volume_name = var.BASE_VOLUME_NAME
  base_volume_pool = var.BASE_IMAGE_POOL
  format           = "qcow2"
  size             = 250 * 1024 * 1024 * 1024
  name             = "compute-openstack-disk-${count.index}.qcow2"
}


# Define template for cloud_init
data "template_file" "user_data_os_compute" {
  count = var.COMPUTES_COUNT
  vars = {
    hostname       = "os-compute-${count.index}"
    is_admin       = false
    ssh_public_key = local.ssh_public_key
  }
  template = file("${path.module}/cloud-init.cfg")
}

# Network configuration
data "template_file" "network_config_compute" {
  count = var.COMPUTES_COUNT
  vars = {
    n_ip = 20 + count.index
  }
  template = file("${path.module}/network-config.cfg")
}

# Use CloudInit to add the instance
resource "libvirt_cloudinit_disk" "cloudinit_os_compute" {
  count          = var.COMPUTES_COUNT
  name           = "cloudinit_os_compute-${count.index}.iso"
  pool           = var.CLOUD_INIT_POOL
  user_data      = data.template_file.user_data_os_compute[count.index].rendered
  network_config = data.template_file.network_config_compute[count.index].rendered
}

# Define KVM domain to create
resource "libvirt_domain" "os-compute" {
  count  = var.COMPUTES_COUNT
  name   = "os-compute-${count.index}"
  memory = "16384"
  vcpu   = var.COMPUTES_VCPU

  network_interface {
    network_name = "osnet"
  }

  network_interface {
    network_name = "osnet"
  }

  network_interface {
    network_name = "osnet"
  }

  network_interface {
    network_name = "os-external"
  }

  disk {
    volume_id = libvirt_volume.compute_openstack_disk[count.index].id
  }

  cpu = {
    mode = "host-passthrough"
  }

  cloudinit = libvirt_cloudinit_disk.cloudinit_os_compute[count.index].id

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
