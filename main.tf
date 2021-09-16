data "ibm_is_image" "image" {
  name = "ibm-ubuntu-20-04-2-minimal-amd64-1"
}

data "ibm_is_ssh_key" "sshkey" {
  name = var.ssh_keyname
}

data "ibm_resource_group" "group" {
  name = var.resource_group_name
}

provider "ibm" {
  alias  = "primary"
  region = var.region
}

resource "ibm_is_vpc" "vpc" {
  name           = var.vpc_name
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_public_gateway" "public_gateway" {
  name = "autoscale-pub-gateway"
  vpc  = ibm_is_vpc.vpc.id
  zone = "${var.region}-1"
  resource_group           = data.ibm_resource_group.group.id

  //User can configure timeouts
  timeouts {
    create = "90m"
  }
}

resource "ibm_is_public_gateway" "public_gateway2" {
  name = "autoscale-pub-gateway2"
  vpc  = ibm_is_vpc.vpc.id
  zone = "${var.region}-2"
  resource_group           = data.ibm_resource_group.group.id

  //User can configure timeouts
  timeouts {
    create = "90m"
  }
}

resource "ibm_is_subnet" "subnet1" {
  name                     = "${var.vpc_name}-subnet-1"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = "${var.region}-1"
  public_gateway            = ibm_is_public_gateway.public_gateway.id
  resource_group           = data.ibm_resource_group.group.id
  total_ipv4_address_count = "256"
}

resource "ibm_is_subnet" "subnet2" {
  name                     = "${var.vpc_name}-subnet-2"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = "${var.region}-2"
  public_gateway            = ibm_is_public_gateway.public_gateway2.id
  resource_group           = data.ibm_resource_group.group.id
  total_ipv4_address_count = "256"
}

resource "ibm_is_security_group" "security_group" {
  name           = "${var.vpc_name}-lb-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group_rule" "security_group_rule_in" {
  group     = ibm_is_security_group.security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
}

resource "ibm_is_security_group_rule" "security_group_rule_out" {
  group     = ibm_is_security_group.security_group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

resource "ibm_is_instance_template" "instance_template" {
  name           = "${var.basename}-instance-template"
  image          = data.ibm_is_image.image.id
  profile        = "cx2-2x4"
  resource_group = data.ibm_resource_group.group.id

  primary_network_interface {
    subnet          = ibm_is_subnet.subnet1.id
    security_groups = [ibm_is_security_group.security_group.id]
  }

  vpc       = ibm_is_vpc.vpc.id
  zone      = "${var.region}-1"
  keys      = [data.ibm_is_ssh_key.sshkey.id]
  user_data = file("./scripts/script.sh")
#  user_data = var.enable_end_to_end_encryption ? file("./scripts/install-software-ssl.sh") : file("./scripts/install-software.sh")
}

resource "ibm_is_lb" "lb" {
  name            = "${var.vpc_name}-lb"
  subnets         = [ibm_is_subnet.subnet1.id, ibm_is_subnet.subnet2.id]
  security_groups = [ibm_is_security_group.security_group.id]
  resource_group  = data.ibm_resource_group.group.id
}

resource "ibm_is_lb_listener" "lb-listener" {
  lb                   = ibm_is_lb.lb.id
  port                 = "80"
  protocol             = "tcp"
  default_pool         = element(split("/", ibm_is_lb_pool.lb-pool.id), 1)
  certificate_instance = var.certificate_crn == "" ? "" : var.certificate_crn
}

resource "ibm_is_lb_pool" "lb-pool" {
  lb                 = ibm_is_lb.lb.id
  name               = "${var.vpc_name}-lb-pool"
  protocol           = "tcp"
  algorithm          = "round_robin"
  health_delay       = "15"
  health_retries     = "2"
  health_timeout     = "5"
  health_type        = "tcp"
  health_monitor_url = "/"
}


resource "ibm_is_instance_group" "instance_group" {
  provider      = ibm.primary
  name               = "${var.basename}-instance-group"
  instance_template  = ibm_is_instance_template.instance_template.id
  instance_count     = 1
  subnets            = [ibm_is_subnet.subnet1.id, ibm_is_subnet.subnet2.id]
  resource_group           = data.ibm_resource_group.group.id
  load_balancer      = ibm_is_lb.lb.id
  load_balancer_pool = element(split("/", ibm_is_lb_pool.lb-pool.id), 1)
  application_port   = var.enable_end_to_end_encryption ? 443 : 80
  depends_on = [ibm_is_lb_listener.lb-listener, ibm_is_lb_pool.lb-pool, ibm_is_lb.lb]
}

resource "ibm_is_instance_group_manager" "instance_group_manager" {
  name                 = "${var.basename}-instance-group-manager"
  aggregation_window   = 90
  instance_group       = ibm_is_instance_group.instance_group.id
  cooldown             = 120
  manager_type         = "autoscale"
  enable_manager       = true
  max_membership_count = 5
}

resource "ibm_is_instance_group_manager_policy" "cpuPolicy" {
  instance_group         = ibm_is_instance_group.instance_group.id
  instance_group_manager = ibm_is_instance_group_manager.instance_group_manager.manager_id
  metric_type            = "cpu"
  metric_value           = 30
  policy_type            = "target"
  name                   = "${var.basename}-instance-group-manager-policy"
}

output "LOAD_BALANCER_HOSTNAME" {
  value = ibm_is_lb.lb.hostname
}
