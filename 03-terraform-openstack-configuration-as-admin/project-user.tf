# Set variables
variable "user_password" {
  description = "Password of the user user"
  type        = string
  sensitive   = true

  # Remove the following line and 'export TF_VAR_user_password="mysecretpassword"' instead
  default = "mysecretpassword"
}

variable "project_name" {
  type = string
  default = "jicg-project"
}

variable "user_name" {
  type = string
  default = "jicg"
}


# openstack pproject create --domain default user_project
resource "openstack_identity_project_v3" "user_project" {
  name        = var.project_name
  description = "A new user project"
}

# openstack user create --password misecretpassword user
resource "openstack_identity_user_v3" "user" {
  default_project_id = openstack_identity_project_v3.user_project.id
  name               = var.user_name
  description        = "A non admin user to deploy things"

  password = var.user_password
}

# Query the role "member" - So I can access it using data.openstack_identity_role_v3.member...
# Openstack cli, this hcl snippet would translate to:
#     openstack role show member
data "openstack_identity_role_v3" "member" {
    name = "member"
}

# Openstack role assignment list
resource "openstack_identity_role_assignment_v3" "role_assignment_1" {
  user_id    = openstack_identity_user_v3.user.id
  project_id = openstack_identity_project_v3.user_project.id
  role_id    = data.openstack_identity_role_v3.member.id
}
