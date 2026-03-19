# --centralized => distributed = false
resource "openstack_networking_router_v2" "rt_ext" {
  name = "rt-ext"
  external_network_id = openstack_networking_network_v2.ext_net.id
}

# Router interface to subnet
resource "openstack_networking_router_interface_v2" "rt_ext_interface" {
  router_id = openstack_networking_router_v2.rt_ext.id
  subnet_id = openstack_networking_subnet_v2.subnet_int_net.id
}
