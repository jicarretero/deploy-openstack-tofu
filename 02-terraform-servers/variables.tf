variable "COMPUTES_COUNT" {
  default = 3
  type    = number
}

variable "DEFAULT_DISK_POOL" {
  default = "default"
  type    = string
}

variable "BASE_IMAGE_POOL" {
  default = "base-image-pool"
  type    = string
}

variable "CLOUD_INIT_POOL" {
  default = "cloud-init-pool"
  type    = string
}

variable "BASE_VOLUME_NAME" {
  default = "noble-server-cloudimg-amd64.img"
  type    = string
}

variable "ADMIN_RAM" {
  default = 12288
  type    = number
}

variable "ADMIN_VCPUS" {
  default = 6
  type    = number
}

variable "COMPUTES_VCPUS" {
  default = 6
  type    = number
}
