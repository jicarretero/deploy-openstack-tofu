locals {
  // I will use my id_ed25519.pub file. I will load it from the file
  ssh_public_key = file(pathexpand("~/.ssh/id_ed25519.pub"))
}

resource "openstack_compute_keypair_v2" "demo_keypair" {
  name       = "demo_keypair"
  public_key = local.ssh_public_key
}
