
## Terraform / Openstack installation

[Documentación del Driver](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs)

[Primeros pasos con Openstack](https://medium.com/@joseignacio.carretero/openstack-some-first-steps-c97d6784edb1)


## Configurar el provider

```hcl
# Define required providers
terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53.0"
    }
  }
}

# Configure the OpenStack Provider
provider "openstack" {
  user_name   = "admin"
  tenant_name = "admin"
  password    = "ujAseH1Y0yl57bPVaRP1TqwpwgZKLYbrsi7uWLeh"
  auth_url    = "http://os-admin.openstack.mine:5000/v3"
  region      = "corporario"
}
```

## Crear images para glance

```hcl
resource "openstack_images_image_v2" "cirros" {
  name             = "cirros"
  image_source_url = "https://download.cirros-cloud.net/0.6.3/cirros-0.6.3-x86_64-disk.img"
  container_format = "bare"
  disk_format      = "qcow2"
  visibility       = "public"

  properties = {
    key = "value"
  }
}

resource "openstack_images_image_v2" "fedora-coreos-43" {
  name             = "fedora-coreos-43"
  local_file_path  = "/var/lib/libvirt/base-image-pool/fedora-coreos-43.20260217.3.1-qemu.x86_64.qcow2"
  container_format = "bare"
  disk_format      = "qcow2"
  visibility       = "public"

  properties = {
    key = "value"
  }
}

```


## Crear Compute flavors

Ejemplo - 

```hcl
resource "openstack_compute_flavor_v2" "tiny-flavor" {
    name = "tiny-flavor"
    ram  = "1024"
    vcpus = "1"
    disk = "10"
    is_public = true
}
```

- **Nota**: Se puede cambiar, por ejemplo en nombre del flavor de *tiny-flavor* por *tiny* y se modificará el flavor. No se creará otro.

- **NOTA2**: Voy a hacerlo en buclo, así que quiero borrar mi recurso "tiny-flavor" - Para ello uso `terraform state list` y `terraform destroy -target=xxx`

```bash
❯ terraform state list
openstack_compute_flavor_v2.tiny-flavor
openstack_images_image_v2.cirros
openstack_images_image_v2.fedora-coreos-43
❯ terraform destroy -target=openstack_compute_flavor_v2.tiny-flavor
openstack_compute_flavor_v2.tiny-flavor: Refreshing state... [id=41923a59-db7a-44a7-b37f-4b444d60e183]
``` 

Ahora, como quiero crear 3 flavors, pues puedo crearme un mapa e iterar sobre él:

```hcl
variable "flavors" {
  description = "Lista de flavors a crear"
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
```

```hcl
resource "openstack_compute_flavor_v2" "flavors" {
  for_each = var.flavors

  name  = each.key
  ram   = each.value.ram
  vcpus = each.value.vcpus
  disk  = each.value.disk

  # opcional: visibilidad pública
  is_public = true
}
```


## Redes

Supongamos que he creado la red ext-net y la subred sub-ext-net tal que así (tipo Openstack):

```bash
openstack network create --external \
--provider-network-type flat \
--provider-physical-network physnet1 ext-net

# Create the subnet - 
openstack subnet create --network ext-net \
--allocation-pool start=10.202.254.16,end=10.202.254.254 \
--dns-nameserver 8.8.8.8 --gateway 10.202.254.1 \
--subnet-range 10.202.254.0/24 sub-ext-net
```

Puedo crear el fichero siguiente:

```hcl
resource "openstack_networking_network_v2" "network_1" {
  name           = "ext-net"
}

resource "openstack_networking_subnet_v2" "subnetwork_1" {
  name           = "sub-ext-net"
}
```

y luego importar la red:

```bash
# Primero averiguo los ids de las redes:
openstack network list

# Y luego ya puedo importo la red
terraform import openstack_networking_network_v2.network_1 1533950c-da68-41d4-9378-97f7d8d15b2c

# Importo la subred
terraform import openstack_networking_subnet_v2.subnetwork_1 54984c5f-fc20-42ac-abce-082ed41a722c
```

... Esto me vale para preparar el **hcl** pa luego.

```hcl
# Red interna
# Create an internal Network -- A shared network for everybody
resource "openstack_networking_network_v2" "internal" {
  name           = "internal"
  admin_state_up = "true"
  shared = "true"
}

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
```

```hcl
# Red External
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
```

## Router
Hay que crear por separado el router y el interfaz con la red interna

```hcl
# --centralized => distributed = false
resource "openstack_networking_router_v2" "rt_ext" {
  name = "rt-ext"
  external_network_id = openstack_networking_network_v2.ext_net.id
}

# Router interface to subnet
resource "openstack_networking_router_interface_v2" "rt_ext_interface" {
  router_id = openstack_networking_router_v2.rt_ext.id
  subnet_id = openstack_networking_subnet_v2.subnet_int_net.id
}
```

## User / Project / Role

Creamos proyecto
```hcl
resource "openstack_identity_project_v3" "jicg_project" {
  name        = "jicg_project"
  description = "User project, for jicg"
}
```


Creamos Usuario
```hcl
resource "openstack_identity_user_v3" "user_1" {
  default_project_id = openstack_identity_project_v3.project_1.id
  name               = "jicg"
  description        = "A non admin user to deploy things"

  password = "mysecretpassword"
}
```

Creamos el role assignment list
```hcl
# Query the role "member" - So I can access it using data.openstack_identity_role_v3.member...
# openstack role show member
data "openstack_identity_role_v3" "member" {
    name = "member"
}

# Openstack role assignment list
resource "openstack_identity_role_assignment_v3" "role_assignment_1" {
  user_id    = openstack_identity_user_v3.user_jicg.id
  project_id = openstack_identity_project_v3.jicg_project.id
  role_id    = data.openstack_identity_role_v3.member.id
}
```

# Algo de seguridad con algunas variables.

Puedo crear, y no subir el fichero "terraform.tfvars" con los passwords de Openstack. Para ello, creo el fichero "variables.tf"

```hcl
# variables.tf
variable "openstack_password" {
  description = "OpenStack password"
  type        = string
  sensitive   = true
}

variable "jicg_password" {
  description = "User jicg password"
  type = string
  sensitive = true
}
```

```hcl
# terraform.tfvars

openstack_password="ujAseH1Y0yl57bPVaRP1TqwpwgZKLYbrsi7uWLeh"
jicg_password="mysecretpassword"

```

O, simplemente, puedo declarar las variables de entorno (sin fichero tfvars)

```bash
export TF_VAR_openstack_password="ujAseH1Y0yl57bPVaRP1TqwpwgZKLYbrsi7uWLeh"
export TF_VAR_jicg_password="mysecretpassword"
```


