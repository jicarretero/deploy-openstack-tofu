# Create an internal Network -- A shared network for everybody
resource "openstack_networking_network_v2" "internal" {
  name           = var.internal_network_name
  admin_state_up = "true"
  shared         = "true"
}

# --dns-nameserver 8.8.8.8 --gateway 192.168.192.1 --dhcp \
# --allocation-pool start=192.168.192.3,end=192.168.192.254 \


# Create a Subnetwork in our shared network
resource "openstack_networking_subnet_v2" "subnet_int_net" {
  name            = var.internal_subnet_name
  network_id      = openstack_networking_network_v2.internal.id
  cidr            = var.internal_subnet_cidr
  ip_version      = 4
  gateway_ip      = var.internal_subnet_gateway
  enable_dhcp     = true
  dns_nameservers = var.internal_subnet_dns_nameservers
  allocation_pool {
    start = var.internal_subnet_allocation_pool_start
    end   = var.internal_subnet_allocation_pool_end
  }
}

