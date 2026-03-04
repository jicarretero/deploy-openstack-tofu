# Provisioning Infrastructure with Terraform and Libvirt for OpenStack Deployment

This repo is created to support the article: https://jicg.eu/provisioning-infrastructure-with-terraform-and-libvirt-for-openstack-deployment/


## 0 - Libvirt volume pools
I use 3 separate pools for my Terraform deployments on libvirt, and things are configured this way in the terraform files.

- **default** - I use this one to store the Virtual Server disks. The directory for this pool is `/var/lib/libvirt/images`. It tis the default one and it is created with the installation of libvirt software. 
- **base-image-pool** - I use this one to store Virtual server images. Those which are the base to create vms. In my case this directory is `/var/lib/libvirt/base-image-pool`.
- **cloud-init-pool** - I use this one to create that kind of "cdrom" images that cloud init generates for each virtual server. In my case, the directory is `/var/lib/libvirt/cloud-init-pool`.

If you want to create these pools (once in life is enough), just type these commands:

```bash
cd terraform-pool-configuration

terraform init
terraform apply
```

The creation of these pools are optional. If you only want to use the "default" one, change the file `terraform-servers/variables.tf`and set the variables *BASE_IMAGE_POOL* and *CLOUD_IMAGE_POOL* to the value `default`.

## 1 - Network creation
In order to create the networks we use in the configuration

```bash
cd terraform-network

terraform init
terraform apply
``` 

**WARNING**: Libvirt creates the networks, and in the case of a NATED network (os-external), it will create the bridges in Linux. However, regarding the internal openstack network (osnet), it will just describe that there is a bridge with the name `br-os` that this net will use, however, this bridge is not created. Libvirt doesn't make the bridges *vlan aware*, which will cause a broken networking. So, we need to:

- Create the bridge `br-os`

```bash
# Create the bridge for the bridged "osnet" Network
sudo ip link add br-os type bridge
```

- Make the bridges be aware of *vlan tags*:

```bash
# Let br-os and br-os-ext be aware of vlans
sudo ip link add br-os type bridge vlan_filtering 1
sudo ip link add br-os-ext type bridge vlan_filtering 1
sudo ip link set br-os up
sudo ip link set br-os-ext up
``` 

Both of these snippets are in file `set-vlans-to-routers.sh`. We should run this script before starting the VMs.


## 2 - VM Creation

In order to create the VMs, we can run:

```bash
cd terraform-servers

terraform init
terraform apply
```

This will create 5 VMs as described in the article.

## 3 - Openstack deployment
The deployment of Openstack is in [kolla](kolla/README.md) directory.


