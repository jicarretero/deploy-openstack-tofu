resource "libvirt_volume" "routing_openstack_disk" {
  name     = "routing_openstack_disk.qcow2"
  pool     = var.DEFAULT_DISK_POOL
  capacity = 25 * 1024 * 1024 * 1024

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

# Use CloudInit to add the instance
resource "libvirt_cloudinit_disk" "cloudinit_os_routing" {
  name = "cloudinit_os_routing"

  meta_data = jsonencode({
    "instance-id"    = "os-routing"
    "local-hostname" = "os-routing"
  })

  user_data = templatefile("${path.module}/cloud-init-routing.cfg", {
    hostname       = "os-routing"
    ssh_public_key = local.ssh_public_key
  })

  network_config = file("${path.module}/network-config-routing.cfg")
}


resource "libvirt_volume" "cloudinit_os_routing_vol" {
  name = "cloudinit_os_routing.iso"
  pool = var.CLOUD_INIT_POOL

  create = {
    content = {
      url = libvirt_cloudinit_disk.cloudinit_os_routing.path
    }
  }
}

# Define KVM domain to create
resource "libvirt_domain" "os-routing" {
  name        = "os-routing"
  running     = true
  memory      = 2048
  memory_unit = "MiB"
  vcpu        = 2
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
      {
        source = {
          volume = {
            pool   = libvirt_volume.routing_openstack_disk.pool
            volume = libvirt_volume.routing_openstack_disk.name
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
      # Cloud-init ISO
      {
        device = "cdrom"
        source = {
          volume = {
            pool   = libvirt_volume.cloudinit_os_routing_vol.pool
            volume = libvirt_volume.cloudinit_os_routing_vol.name
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
      # NAT virtual network — source.network is correct
      {
        type  = "network"
        mac   = { address = "52:54:00:22:be:05" }
        model = { type = "virtio" }
        source = {
          network = {
            network = "default"
          }
        }
      },
      # bridge network (br-os) — must use source.bridge
      {
        type  = "bridge"
        model = { type = "virtio" }
        source = {
          bridge = {
            bridge = "br-os"
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
