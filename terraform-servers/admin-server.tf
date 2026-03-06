resource "libvirt_volume" "admin_openstack_disk" {
  name     = "admin_openstack_disk.qcow2"
  pool     = var.DEFAULT_DISK_POOL
  capacity = 60 * 1024 * 1024 * 1024

  target = {
    format = {
      type = "qcow2"
    }
  }

  backing_store = {
    type = "file"
    path = "${var.BASE_IMAGE_POOL_PATH}/${var.BASE_VOLUME_NAME}"
    format = {
      type = "qcow2"
    }
  }
}

resource "libvirt_volume" "admin_volume_disk" {
  name     = "admin_volume_disk.qcow2"
  pool     = var.DEFAULT_DISK_POOL
  capacity = 300 * 1024 * 1024 * 1024

  target = {
    format = {
      type = "qcow2"
    }
  }
}

# Use CloudInit to add the instance
resource "libvirt_cloudinit_disk" "cloudinit_os_admin" {
  name = "cloudinit_os_admin"

  meta_data = jsonencode({
    "instance-id"    = "os-admin"
    "local-hostname" = "os-admin"
  })

  user_data = templatefile("${path.module}/cloud-init.cfg", {
    is_admin       = true
    hostname       = "os-admin"
    ssh_public_key = local.ssh_public_key
  })

  network_config = templatefile("${path.module}/network-config.cfg", {
    n_ip = 2
  })
}


resource "libvirt_volume" "cloudinit_os_admin_vol" {
  name = "cloudinit_os_admin.iso"
  pool = var.CLOUD_INIT_POOL # List storage pools using virsh pool-list

  create = {
    content = {
      url = libvirt_cloudinit_disk.cloudinit_os_admin.path
    }
  }
}

# Define KVM domain to create
resource "libvirt_domain" "os-admin" {
  name        = "os-admin"
  running     = true
  memory      = var.ADMIN_RAM
  memory_unit = "MiB"
  vcpu        = var.ADMIN_VCPUS
  type        = "kvm"

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }

  cpu = {
    mode = "host-passthrough"
  }

  features = {
    acpi = true
    apic = {
      eoi = "on"
    }
    pae = true
  }

  devices = {
    disks = [
      # ens3 boot disk
      {
        source = {
          volume = {
            pool   = libvirt_volume.admin_openstack_disk.pool
            volume = libvirt_volume.admin_openstack_disk.name
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
        driver = {
          name = "qemu"
          type = "qcow2"
        }
      },
      # Extra volume disk
      {
        source = {
          volume = {
            pool   = libvirt_volume.admin_volume_disk.pool
            volume = libvirt_volume.admin_volume_disk.name
          }
        }
        target = {
          dev = "vdb"
          bus = "virtio"
        }
        driver = {
          name = "qemu"
          type = "qcow2"
        }
      },
      # Cloud-init ISO
      {
        device = "cdrom"
        source = {
          volume = {
            pool   = libvirt_volume.cloudinit_os_admin_vol.pool
            volume = libvirt_volume.cloudinit_os_admin_vol.name
          }
        }
        target = {
          dev = "sda"
          bus = "usb"
        }
        driver = {
          name = "qemu"
          type = "raw"
        }
      }
    ]

    interfaces = [
      # ens3 — bridge network (br-os), must use source.bridge
      {
        type  = "bridge"
        model = { type = "virtio" }
        source = {
          bridge = {
            bridge = "br-os"
          }
        }
      },
      # ens4
      {
        type  = "bridge"
        model = { type = "virtio" }
        source = {
          bridge = {
            bridge = "br-os"
          }
        }
      },
      # ens5 — NAT virtual network, source.network is correct
      {
        type  = "network"
        model = { type = "virtio" }
        source = {
          network = {
            network = "os-external"
          }
        }
      }
    ]

    consoles = [
      {
        target = {
          type = "serial"
          port = 0
        }
      }
    ]

    graphics = [
      {
        vnc = {
          auto_port = true
          listen    = "127.0.0.1"
        }
      }
    ]
  }

  # Workaround for provider bug: source.network is read back as null after apply
  # https://github.com/dmacvicar/terraform-provider-libvirt/issues
  lifecycle {
    ignore_changes = [devices]
  }
}
