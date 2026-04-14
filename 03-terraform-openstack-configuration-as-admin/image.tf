# Images - Set values in variables.tf
resource "openstack_images_image_v2" "images" {
  for_each         = var.images
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
