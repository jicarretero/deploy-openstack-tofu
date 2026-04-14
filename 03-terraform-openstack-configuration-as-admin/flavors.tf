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
