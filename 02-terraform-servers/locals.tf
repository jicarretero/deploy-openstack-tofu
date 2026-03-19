### Cloud init file
locals {
  // I will use my id_rsa.pub file. I will load it from the file
  ssh_public_key = file(pathexpand("~/.ssh/id_rsa.pub"))
}

