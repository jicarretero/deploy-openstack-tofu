# Create an internal Network -- A shared network for everybody
resource "openstack_networking_network_v2" "internal" {
  name           = "internal"
  admin_state_up = "true"
  shared = "true"
}

# --dns-nameserver 8.8.8.8 --gateway 192.168.192.1 --dhcp \
# --allocation-pool start=192.168.192.3,end=192.168.192.254 \


# Create a Subnetwork in our shared network
resource "openstack_networking_subnet_v2" "subnet_int_net" {
  name       = "subnet-int-net"
  network_id = openstack_networking_network_v2.internal.id
  cidr       = "192.168.192.0/24"
  ip_version = 4
  gateway_ip = "192.168.192.1"
  enable_dhcp = true
  dns_nameservers = [
        "8.8.8.8",
  ]
  allocation_pool {
        end   = "192.168.192.254"
        start = "192.168.192.3"
  }
}

