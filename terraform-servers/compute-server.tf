resource "libvirt_volume" "compute_openstack_disk" {
  count    = var.COMPUTES_COUNT
  name     = "compute-openstack-disk-${count.index}.qcow2"
  pool     = var.DEFAULT_DISK_POOL
  capacity = 250 * 1024 * 1024 * 1024

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
resource "libvirt_cloudinit_disk" "cloudinit_os_compute" {
  count = var.COMPUTES_COUNT
  name  = "cloudinit_os_compute-${count.index}"

  meta_data = jsonencode({
    "instance-id"    = "os-compute-${count.index}"
    "local-hostname" = "os-compute-${count.index}"
  })

  user_data = templatefile("${path.module}/cloud-init.cfg", {
    hostname       = "os-compute-${count.index}"
    is_admin       = false
    ssh_public_key = local.ssh_public_key
  })

  network_config = templatefile("${path.module}/network-config.cfg", {
    n_ip = 20 + count.index
  })
}


resource "libvirt_volume" "cloudinit_os_compute_vol" {
  count = var.COMPUTES_COUNT
  name  = "cloudinit_os_compute-${count.index}.iso"
  pool  = var.CLOUD_INIT_POOL

  create = {
    content = {
      url = libvirt_cloudinit_disk.cloudinit_os_compute[count.index].path
    }
  }
}

# Define KVM domain to create
resource "libvirt_domain" "os-compute" {
  count       = var.COMPUTES_COUNT
  running     = true
  name        = "os-compute-${count.index}"
  memory      = 16384
  memory_unit = "MiB"
  vcpu        = var.COMPUTES_VCPUS
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
            pool   = libvirt_volume.compute_openstack_disk[count.index].pool
            volume = libvirt_volume.compute_openstack_disk[count.index].name
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
            pool   = libvirt_volume.cloudinit_os_compute_vol[count.index].pool
            volume = libvirt_volume.cloudinit_os_compute_vol[count.index].name
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
      # bridge network (br-os) — must use source.bridge
      {
        type  = "bridge"
        model = { type = "virtio" }
        source = {
          bridge = {
            bridge = "br-os"
          }
        }
      },
      {
        type  = "bridge"
        model = { type = "virtio" }
        source = {
          bridge = {
            bridge = "br-os"
          }
        }
      },
      {
        type  = "bridge"
        model = { type = "virtio" }
        source = {
          bridge = {
            bridge = "br-os"
          }
        }
      },
      # NAT virtual network — source.network is correct
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
