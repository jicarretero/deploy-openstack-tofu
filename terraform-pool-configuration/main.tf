terraform {
  required_providers {
    libvirt = {
      source  = "multani/libvirt"
      version = "0.6.3-1+4"
    }
  }
}

// Connect to local libvirt
provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "base-image-pool" {
  name = "base-image-pool"
  type = "dir"
  path = "/data/libvirt/base-image-pool"
}

resource "libvirt_pool" "cloud-init-pool" {
  name = "cloud-init-pool"
  type = "dir"
  path = "/data/libvirt/cloud-init-pool"
}
