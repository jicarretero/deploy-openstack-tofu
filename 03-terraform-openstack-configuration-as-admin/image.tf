# List of images to upload - 

variable "images" {
   description = "List of images to upload with some of their properties"
   type = map(object({
      filename = string
      hd = number
      ram = number
   }))

   default = {
      cirros = {
         filename = "/var/lib/libvirt/base-image-pool/cirros-0.6.3-x86_64-disk.img"
         hd = 1
         ram  = 512
      }
      ubuntu-2404 = {
         filename = "/var/lib/libvirt/base-image-pool/noble-server-cloudimg-amd64.img"
         hd = 10
         ram  = 2048
      }
      fedoracore-43 = {
         filename = "//var/lib/libvirt/base-image-pool/fedora-coreos-43.20260217.3.1-qemu.x86_64.qcow2"
         hd = 30
         ram  = 4096
      }
   }
}

resource "openstack_images_image_v2" "images" {
  for_each = var.images
  name             = each.key
  local_file_path  = each.value.filename
  container_format = "bare"
  disk_format      = "qcow2"
  visibility       = "public"

  min_disk_gb = each.value.hd
  min_ram_mb  = each.value.ram

  properties = {
    key = "value"
  }
}
