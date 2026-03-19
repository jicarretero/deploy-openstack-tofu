# Create an internal Network -- A shared network for everybody
resource "openstack_networking_network_v2" "ext_net" {
  name           = "ext-net"
  admin_state_up = "true"
  external = "true"
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
  name       = "sub-ext-net"
  network_id = openstack_networking_network_v2.ext_net.id
  cidr       = "10.202.254.0/24"
  ip_version = 4
  gateway_ip = "10.202.254.1"
  enable_dhcp = true
  dns_nameservers = ["8.8.8.8"]
  allocation_pool {
        end   = "10.202.254.254"
        start = "10.202.254.16"
  }
}

