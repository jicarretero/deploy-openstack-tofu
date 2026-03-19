# Provisioning Infrastructure with Terraform and Libvirt for OpenStack Deployment

This repo is created to support the article: https://jicg.eu/provisioning-infrastructure-with-terraform-and-libvirt-for-openstack-deployment/


## 0 - Libvirt volume pools
I use 3 separate pools for my Terraform deployments on libvirt, and things are configured this way in the terraform files.

- **default** - I use this one to store the Virtual Server disks. The directory for this pool is `/var/lib/libvirt/images`. It tis the default one and it is created with the installation of libvirt software. 
- **base-image-pool** - I use this one to store Virtual server images. Those which are the base to create vms. In my case this directory is `/var/lib/libvirt/base-image-pool`.
- **cloud-init-pool** - I use this one to create that kind of "cdrom" images that cloud init generates for each virtual server. In my case, the directory is `/var/lib/libvirt/cloud-init-pool`.

If you want to create these pools (once in life is enough), just type these commands:

```bash
cd 00-terraform-pool-configuration

terraform init
terraform apply
```

The creation of these pools are optional. If you only want to use the "default" one, change the file `terraform-servers/variables.tf`and set the variables *BASE_IMAGE_POOL* and *CLOUD_IMAGE_POOL* to the value `default`.

## 1 - Network creation
In order to create the networks we use in the configuration. This part is tricky, because Terraform can create the networks in libvirt, but it is not designed to work with local bridges or local routes. So I'll have to put there some scripts.


```bash
cd 01-terraform-network

terraform init
terraform apply
``` 

**WARNING**: Libvirt creates the networks, and in the case of a NATED network (os-external), it will create the bridges in Linux. However, regarding the internal openstack network (osnet), it will just describe that there is a bridge with the name `br-os` that this net will use, however, this bridge is not created. Libvirt doesn't make the bridges *vlan aware*, which will cause a broken networking. So, we need to:

- Run the script `01-create-router-n-set-vlans.sh` before starting VMs.

- Run the script `02-vlan-setup-vlan50.sh` later, when the VMs are up. It is useless running it now.

 
## 2 - VM Creation

In order to create the VMs, we can run:

```bash
cd 02-terraform-servers

terraform init
terraform apply
```

This will create 5 VMs as described in the article.

Once the VMs are ready, you can run the script `02-vlan-setup-vlan50.sh`. This script will create the 
*gateway* for Openstack external network in the vlan50 (as a veth device) and will add the vlan-id to all the bridges that connect the virtual servers.

## 3 - Openstack deployment
The deployment of Openstack is in [kolla](kolla/README.md) directory.
