resource "libvirt_volume" "admin_openstack_disk" {
  name             = "admin_openstack_disk.qcow2"
  pool             = var.DEFAULT_DISK_POOL
  base_volume_name = var.BASE_VOLUME_NAME
  base_volume_pool = var.BASE_IMAGE_POOL
  format           = "qcow2"
  size             = 60 * 1024 * 1024 * 1024
}

resource "libvirt_volume" "admin_volume_disk" {
  name   = "admin_volume_disk.qcow2"
  format = "qcow2"
  size   = 300 * 1024 * 1024 * 1024
}

# Define template for cloud_init
data "template_file" "user_data_os_admin" {
  vars = {
    is_admin       = true
    hostname       = "os-admin"
    ssh_public_key = local.ssh_public_key
  }
  template = file("${path.module}/cloud-init.cfg")
}

# Network configuration
data "template_file" "network_config_admin" {
  vars = {
    n_ip = 2
  }
  template = file("${path.module}/network-config.cfg")
}

# Use CloudInit to add the instance
resource "libvirt_cloudinit_disk" "cloudinit_os_admin" {
  name           = "cloudinit_os_admin.iso"
  pool           = var.CLOUD_INIT_POOL # List storage pools using virsh pool-list
  user_data      = data.template_file.user_data_os_admin.rendered
  network_config = data.template_file.network_config_admin.rendered
}

# Define KVM domain to create
resource "libvirt_domain" "os-admin" {
  name   = "os-admin"
  memory = var.ADMIN_RAM
  vcpu   = var.ADMIN_VCPUS

  # ens3
  network_interface {
    network_name   = "osnet" # List networks with virsh net-list
    wait_for_lease = false
  }

  # ens4
  network_interface {
    network_name = "osnet"
  }

  # ens5
  network_interface {
    network_name = "os-external"
  }

  disk {
    volume_id = libvirt_volume.admin_openstack_disk.id
  }
  disk {
    volume_id = libvirt_volume.admin_volume_disk.id
  }

  cloudinit = libvirt_cloudinit_disk.cloudinit_os_admin.id

  cpu = {
    mode = "host-passthrough"
  }


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
