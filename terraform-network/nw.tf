resource "libvirt_network" "osnet" {
  name    = "osnet"
  forward = { mode = "bridge" }
  bridge  = { name = "br-os" }
}

resource "libvirt_network" "os-external" {
  name      = "os-external"
  forward   = { mode = "nat" }
  bridge    = { name = "br-os-ext" }
  ips = [
    {
      address = "10.202.254.1"
      netmask = "255.255.255.0"
    }
  ]
}
