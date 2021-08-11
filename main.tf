data "ibm_is_image" "image" {
  name = "ibm-ubuntu-18-04-1-minimal-amd64-2"
}

data "ibm_is_ssh_key" "sshkey" {
  name = var.ssh_keyname
}

data "ibm_resource_group" "group" {
  name = var.resource_group_name
}

resource "ibm_is_vpc" "vpc" {
  name           = var.vpc_name
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_subnet" "subnet" {
  count                    = 2
  name                     = "${var.vpc_name}-subnet-${count.index + 1}"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = "${var.region}-${count.index + 1}"
  resource_group           = data.ibm_resource_group.group.id
  total_ipv4_address_count = "256"
}

resource "ibm_is_public_gateway" "public_gateway" {
  name = "autoscale-pub-gateway"
  vpc  = ibm_is_vpc.vpc.id
  zone = "us-south-1"

  //User can configure timeouts
  timeouts {
    create = "90m"
  }
}

resource "ibm_is_instance_template" "instance_template" {
  name           = "${var.basename}-instance-template"
  image          = data.ibm_is_image.image.id
  profile        = "cx2-2x4"
  resource_group = data.ibm_resource_group.group.id

  primary_network_interface {
    subnet          = ibm_is_subnet.subnet[0].id
  }

  vpc       = ibm_is_vpc.vpc.id
  zone      = "${var.region}-1"
  keys      = [data.ibm_is_ssh_key.sshkey.id]
  user_data = var.enable_end_to_end_encryption ? file("./scripts/install-software-ssl.sh") : file("./scripts/install-software.sh")
}

resource "ibm_is_lb" "lb" {
  name            = "${var.vpc_name}-lb"
  subnets         = ibm_is_subnet.subnet.*.id
  resource_group  = data.ibm_resource_group.group.id
  depends_on = [
    ibm_is_instance_group.instance_group,
  ]
}

resource "ibm_is_lb_pool" "lb-pool" {
  lb                 = ibm_is_lb.lb.id
  name               = "${var.vpc_name}-lb-pool"
  protocol           = var.enable_end_to_end_encryption ? "https" : "http"
  algorithm          = "round_robin"
  health_delay       = "15"
  health_retries     = "2"
  health_timeout     = "5"
  health_type        = var.enable_end_to_end_encryption ? "https" : "http"
  health_monitor_url = "/"
  depends_on = [time_sleep.wait_30_seconds]
}

resource "ibm_is_lb_listener" "lb-listener" {
  lb                   = ibm_is_lb.lb.id
  port                 = var.certificate_crn == "" ? "80" : "443"
  protocol             = var.certificate_crn == "" ? "http" : "https"
  default_pool         = element(split("/", ibm_is_lb_pool.lb-pool.id), 1)
  certificate_instance = var.certificate_crn == "" ? "" : var.certificate_crn
}

resource "ibm_is_instance_group" "instance_group" {
  name               = "${var.basename}-instance-group"
  instance_template  = ibm_is_instance_template.instance_template.id
  instance_count     = 1
  subnets            = ibm_is_subnet.subnet.*.id
  load_balancer      = ibm_is_lb.lb.id
  load_balancer_pool = element(split("/", ibm_is_lb_pool.lb-pool.id), 1)
  application_port   = var.enable_end_to_end_encryption ? 443 : 80
  resource_group     = data.ibm_resource_group.group.id

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
    depends_on = [
    ibm_is_instance_group.instance_group,
  ]
}

resource "ibm_is_instance_group_manager_policy" "cpuPolicy" {
  instance_group         = ibm_is_instance_group.instance_group.id
  instance_group_manager = ibm_is_instance_group_manager.instance_group_manager.manager_id
  metric_type            = "cpu"
  metric_value           = 10
  policy_type            = "target"
  name                   = "${var.basename}-instance-group-manager-policy"
    depends_on = [
    ibm_is_instance_group.instance_group,
  ]
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [ibm_is_lb.lb]

  destroy_duration = "30s"
}

output "LOAD_BALANCER_HOSTNAME" {
  value = ibm_is_lb.lb.hostname
}
