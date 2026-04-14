# Create an internal Network -- A shared network for everybody
resource "openstack_networking_network_v2" "ext_net" {
  name           = var.external_network_name
  admin_state_up = "true"
  external       = "true"
  segments {
    network_type     = "flat"
    physical_network = "physnet1"
    segmentation_id  = 0
  }
}

# --dns-nameserver 8.8.8.8 --gateway 192.168.192.1 --dhcp \
# --allocation-pool start=192.168.192.3,end=192.168.192.254 \


# Create a Subnetwork in our shared network
resource "openstack_networking_subnet_v2" "sub_ext_net" {
  name            = var.external_subnet_name
  network_id      = openstack_networking_network_v2.ext_net.id
  cidr            = var.external_subnet_cidr
  ip_version      = 4
  gateway_ip      = var.external_subnet_gateway
  enable_dhcp     = true
  dns_nameservers = var.external_subnet_dns_nameservers
  allocation_pool {
    end   = var.external_subnet_allocation_pool_end
    start = var.external_subnet_allocation_pool_start
  }
}

