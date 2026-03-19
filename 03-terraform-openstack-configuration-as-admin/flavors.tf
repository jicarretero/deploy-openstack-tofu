# List of flavors to be created
variable "flavors" {
  description = "A list of flavors to be created"
  type = map(object({
    ram   = number
    vcpus = number
    disk  = number
  }))

  default = {
    tiny = {
      ram   = 1024
      vcpus = 1
      disk  = 10
    }
    small = {
      ram   = 2048
      vcpus = 1
      disk  = 20
    }
    medium = {
      ram   = 4096
      vcpus = 2
      disk  = 40
    }
  }
}

# Create the flavors. Iterate in the flavors with the "for_each var.flavors"
resource "openstack_compute_flavor_v2" "flavors" {
  for_each = var.flavors

  name  = each.key
  ram   = each.value.ram
  vcpus = each.value.vcpus
  disk  = each.value.disk

  # opcional: visibilidad pública
  is_public = true
}
