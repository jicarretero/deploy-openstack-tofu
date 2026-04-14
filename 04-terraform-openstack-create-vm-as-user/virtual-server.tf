resource "openstack_compute_instance_v2" "first_ubuntu" {
  name            = "first_ubuntu"
  image_name      = var.image
  flavor_name     = var.flavor
  key_pair        = "demo_keypair"
  security_groups = ["secgroup_1"]

  network {
    name = var.public_network
  }
}

data "openstack_networking_port_v2" "first_ubuntu_port" {
    device_id = openstack_compute_instance_v2.first_ubuntu.id
    network_id = openstack_compute_instance_v2.first_ubuntu.network.0.uuid
}

resource "openstack_networking_floatingip_associate_v2" "fip_vm" {
  floating_ip = openstack_networking_floatingip_v2.floatip_1.address
  port_id     = data.openstack_networking_port_v2.first_ubuntu_port.id
}

