resource "openstack_networking_floatingip_v2" "floatip_1" {
  pool = var.network_pool
}
