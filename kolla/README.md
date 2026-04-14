# Openstack installation with Kolla


In order to install ansible-kolla, we can run the following commands:

```bash
python3 -m venv ~/.venv/kolla-ansible
source ~/.venv/kolla-ansible/bin/activate

pip install -U pip

pip install kolla-ansible==20.3.0 ansible-core==2.18.0

## Create /etc/kolla and let the current user (jicg in my case) own it:
sudo mkdir -p /etc/kolla
sudo chown jicg:jicg /etc/kolla

## Install dependencies
kolla-ansible install-deps
```

## Ansible configuration
In order to configure ansible and prevent problems with logins to the virtual servers, I've added this configuration to `ansible.cfg`:

```text
[defaults]
host_key_checking=False
pipelining=True
forks=20
```

Feel free to change it your way.

## Inventory: multinode
The inventory file I created for this configuration is named `multinode`. A more than 600 lines file containing information for all the different modules.

If you've installed kolla-anisble at `~/.venv/kolla-ansible`, the example multinode file is `~/.venv/kolla-ansible/share/kolla-ansible/ansible/inventory/multinode`. Take it as a template to create your own multinode file.

## Create configuration in /etc/kolla

```bash
sudo make /etc/kolla
sudo chown user:user /etc/kolla
```

### Generate passwords for the installation in /etc/kolla

```bash
# Copy the password template file to /etc/kolla
cp  ~/.venv/kolla-ansible/share/kolla-ansible/etc_examples/kolla/passwords.yml /etc/kolla

# Set new passwords in the template
kolla-genpwd
``` 
### Configure what parts of openstack you want to install

The template file is (again considering you've installed your kolla at `~/.venv/kolla-ansible`), then the template file is `~/.venv/kolla/share/kolla-ansible/etc_examples/kolla/globals.yml`. The configurations are done in this file.

In our case, my configuration file is, in this repo 

```text
.
├── kolla
│   ├── ansible.cfg
│   ├── etc
│   │   └── kolla
│   │       └── globals.yml
```

### Configure things for the installation....
I have copied the `globals.yml`file locally to `./etc/kolla/globals.yml` -- I use to create a symlink so it is in its place -

```bash
ln -s $PWD/etc/kolla/globals.yml /etc/kolla/globals.yml
```

The parts of Openstack that I am installing are (the easy way):

- **openstack_core** - This enables *nova*, *heat* and *horizon* (nova to create/destroy virtual servers, heat for template orchestration and horizon the web console).
- **glance** - To store and retrieve base images and virtual server snapshots.
- **keystone** - The authentication and authorization server.
- **cinder** - To have external volumes in virtual servers.
- **neutron** - The network manager in Openstack. I've also configured Virtual Distributed Routers.

As well as other components which serve the communication between processes (*rabbitmq*), logs collector (*fluentd*), the database for the Openstack components (*MariaDB*),etc.

There are other interesting configurations:

```
# Operating system where things will be installed
# valid values are: ['centos', 'debian', 'rocky', 'ubuntu']
kolla_base_distro: "ubuntu"

# Openstack release - 2025.1 - I might change to 2025.2 soon.
openstack_release: "2025.1"

# Network interfaces - ens3.30 is the Openstack network
network_interface: "ens3.30"
kolla_internal_vip_address: "172.27.30.2"
# fqdn, as defined in DNS server (or maybe in every /etc/hosts in the worlda)
kolla_internal_fqdn: "os-admin.openstack.mine"a

# Where the API is listening.
api_interface: "ens3.30"

# Internal networking for the different servers and virtual routers.
tunnel_interface: "ens4.40"

# External networking. Network connected to the outside world.
neutron_external_interface: "ens5.50"

# What network plugin should I use for internal Openstack networking....? - Openvswitch in this case.
neutron_plugin_agent: "openvswitch"

# The default region name is "regionOne". My name is much better...
openstack_region_name: "corporario"
```

Anyway, please, read the `globals.yml` file, it explains itself pretty well.

#### Configurations with Load Balancer (Octavia) and managed kubernetes (magnum)-

At the beginning of the file `globals.yml`, when I want to be able to run "Octavia" and "Magnum", I add these few lines -- But if you don't know what they are, you can forget about them and work without this configuration:

```yaml
## JICG - Activate octavia and Magnum...
# The next 4 lines are to deploy Octavia (load balancers) and Magnum 
# (an openstack managed openstack)
# neutron_plugin_agent: "ovn"
# enable_redis: true
# enable_octavia: true
# enable_magnum: true

# The next 4 lines are to deploy without Octavia and Magnum.
neutron_plugin_agent: "openvswitch"
enable_redis: false
enable_octavia: false
enable_magnum: false
```

If you need to add Octavia and Magnun, just tweak this file.


## The installation process

You can skip this if you are not an Arch user.

Before continuing, I must admit that I had to do a "small" patch to make the installation "fluently" work. I added 3 lines at the end of the file `~/.venv/kolla-ansible/share/kolla-ansible/ansible/roles/prechecks/vars/main.yml` – It simply complained in the "prechecks" that Archlinux is not supported... now it is. At least in my laptop. BTW I use Arch.

```
# jicg
  Archlinux:
    - "rolling"
```
    
Ok, the last step is the installation:

```
# Bootstrap servers -- ~3 minutes
kolla-ansible bootstrap-servers -i ./multinode

# Prechecks --  ~1 minute
kolla-ansible prechecks -i ./multinode


# Pull the images - It is specially recommended when upgrading too ~7 minutes
kolla-ansible pull -i multinode

# Finally... deploy -- ~11 minutes
kolla-ansible deploy -i ./multinode
```

