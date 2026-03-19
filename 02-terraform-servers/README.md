# Terraform Networking installation

```bash
# run the following commands
terraform init
terraform apply
``` 

This will create Libvirt networks that we are using in the article, in its part 5 **Deploying the servers with OpenTofu**.

The following files are exposed:

```text
├── admin-server.tf
├── cloud-init.cfg
├── cloud-init-routing.cfg
├── compute-server.tf
├── locals.tf
├── main.tf
├── network-config.cfg
├── network-config-routing.cfg
├── README.md
├── routing-server.tf
└── variables.tf
```

### variables 
This file includes some configuration variables that will be used in the other files in other to make the installation a bit more configurable.

### Routing Server files
The files used to configure the routing server are `


