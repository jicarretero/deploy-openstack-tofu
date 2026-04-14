### 
#  GLANCE  -- used in image.tf  #
###
#
# list of images to upload

variable "images" {
  description = "List of images to upload with some of their properties"
  type = map(object({
    filename = string
    hd       = number
    ram      = number
  }))

  default = {
    cirros = {
      filename = "/var/lib/libvirt/base-image-pool/cirros-0.6.3-x86_64-disk.img"
      hd       = 1
      ram      = 512
    }
    ubuntu-2404 = {
      filename = "/var/lib/libvirt/base-image-pool/noble-server-cloudimg-amd64.img"
      hd       = 10
      ram      = 2048
    }
    fedoracore-43 = {
      filename = "//var/lib/libvirt/base-image-pool/fedora-coreos-43.20260217.3.1-qemu.x86_64.qcow2"
      hd       = 30
      ram      = 4096
    }
  }
}


### 
#  FLAVORS  -- used in flavors.tf
###
#
# list of flavors to create
variable "flavors" {
  description = "A list of flavors to be created"
  type = map(object({
    ram   = number
    vcpus = number
    disk  = number
  }))

  default = {
    tiny = {
      ram   = 1024
      vcpus = 1
      disk  = 10
    }
    small = {
      ram   = 2048
      vcpus = 1
      disk  = 20
    }
    medium = {
      ram   = 4096
      vcpus = 2
      disk  = 40
    }
  }
}

###
#  NETWORKING --
###
#
# Variables for external networking
variable "external_network_name" {
  type    = string
  default = "ext-net"
}
variable "external_subnet_name" {
  type    = string
  default = "sub-ext-net"
}
variable "external_subnet_cidr" {
  type    = string
  default = "10.202.254.0/24"
}

variable "external_subnet_gateway" {
  type    = string
  default = "10.202.254.1"
}

variable "external_subnet_dns_nameservers" {
  type    = list(string)
  default = ["8.8.8.8", "8.8.4.4"]
}

variable "external_subnet_allocation_pool_start" {
  type    = string
  default = "10.202.254.16"
}

variable "external_subnet_allocation_pool_end" {
  type    = string
  default = "10.202.254.254"
}

#
# Variables for internal networking
variable "internal_network_name" {
  type    = string
  default = "internal"
}
variable "internal_subnet_name" {
  type    = string
  default = "sunet-int-net"
}
variable "internal_subnet_cidr" {
  type    = string
  default = "192.168.192.0/24"
}

variable "internal_subnet_gateway" {
  type    = string
  default = "192.168.192.1"
}

variable "internal_subnet_dns_nameservers" {
  type    = list(string)
  default = ["8.8.8.8", "8.8.4.4"]
}

variable "internal_subnet_allocation_pool_start" {
  type    = string
  default = "192.168.192.3"
}

variable "internal_subnet_allocation_pool_end" {
  type    = string
  default = "192.168.192.254"
}

#
# Variables for the router
variable "router_name" {
  type    = string
  default = "rt-ext"
}

### 
#  User and group  -- used in project-user.tf  #
###
#
# User and group to create
variable "user_password" {
  description = "Password of the user user"
  type        = string
  sensitive   = true

  # Remove the following line and 'export TF_VAR_user_password="mysecretpassword"' instead
  default = "mysecretpassword"
}

variable "project_name" {
  type    = string
  default = "jicg-project"
}

variable "user_name" {
  type    = string
  default = "jicg"
}
