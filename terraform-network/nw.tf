resource "libvirt_network" "osnet" {
  name   = "osnet"
  mode   = "bridge"
  bridge = "br-os"
}


resource "libvirt_network" "os-external" {
  name      = "os-external"
  mode      = "nat"
  bridge    = "br-os-ext"
  addresses = ["10.202.254.0/24"]
}
