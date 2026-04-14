variable "open_ports" {
  description = "List of open ports that I will add the security group"
  type = map(object({
    protocol         = string
    port_range_min   = number
    port_range_max   = number
    remote_ip_prefix = string
  }))

  default = {
    ssh = {
      protocol         = "tcp"
      port_range_min   = 22
      port_range_max   = 22
      remote_ip_prefix = "0.0.0.0/0"
    }
    http = {
      protocol         = "tcp"
      port_range_min   = 80
      port_range_max   = 80
      remote_ip_prefix = "0.0.0.0/0"
    }
    https = {
      protocol         = "tcp"
      port_range_min   = 443
      port_range_max   = 443
      remote_ip_prefix = "0.0.0.0/0"
    }
    openvpn = {
      protocol         = "udp"
      port_range_min   = 1194
      port_range_max   = 1194
      remote_ip_prefix = "0.0.0.0/0"
    }
    ping = {
      protocol         = "icmp"
      port_range_min   = 0
      port_range_max   = 0
      remote_ip_prefix = "0.0.0.0/0"
    }
  }
}

## Floating IP Pool
variable "network_pool" {
  type    = string
  default = "ext-net"
}

## Data for the VM
variable "vm_name" {
  type    = string
  default = "demovm"
}
variable "image" {
  type    = string
  default = "ubuntu-2404"
}

variable "flavor" {
  type    = string
  default = "small"
}

variable "public_network" {
  type    = string
  default = "internal"
}
