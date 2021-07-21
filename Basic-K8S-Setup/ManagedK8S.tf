provider "alicloud" {
  access_key = "enter your access key"
  secret_key = "enter your secret key"
  region = "ap-southeast-1"
}

variable "k8s_name_prefix" {
  description = "The name prefix used to create managed kubernetes cluster."
  default     = "tf-ack"
}
resource "random_uuid" "this" {}
# The default resource names.
locals {
  k8s_name     = substr(join("-", [var.k8s_name_prefix, random_uuid.this.result]), 0, 63)
  new_vpc_name = "vpc-for-${local.k8s_name}"
  new_vsw_name = "vsw-for-${local.k8s_name}"
  log_project_name = "log-for-${local.k8s_name}"
}
# The Elastic Compute Service (ECS) instance specifications of the worker nodes.
data "alicloud_instance_types" "default" {
  cpu_core_count       = 4
  memory_size          = 8
  kubernetes_node_role = "Worker"
}
// The zone that has sufficient ECS instances of the required specifications.
data "alicloud_zones" "default" {
  available_instance_type = data.alicloud_instance_types.default.instance_types[0].id
}
# The VPC.
resource "alicloud_vpc" "default" {
  vpc_name       = local.new_vpc_name
  cidr_block = "10.1.0.0/21"
}
# The vSwitches.
resource "alicloud_vswitch" "vswitches" {
  vswitch_name              = local.new_vsw_name
  vpc_id            = alicloud_vpc.default.id
  cidr_block        = "10.1.1.0/24"
  zone_id = data.alicloud_zones.default.zones[0].id
}
# The Log Service project.
resource "alicloud_log_project" "log" {
  name        = local.log_project_name
  description = "created by terraform for managedkubernetes cluster"
}

resource "alicloud_cs_managed_kubernetes" "default" {
  # The name of the cluster.
  name                      = local.k8s_name
  count                     = 1
  # The vSwitches of the new Kubernetes cluster. Specify the IDs of one or more vSwitches. The vSwitches must be in the zone specified by availability_zone.
  worker_vswitch_ids        = split(",", join(",", alicloud_vswitch.vswitches. *.id))
  # Specify whether to create a new Network Address Translation (NAT) gateway when the Kubernetes cluster is created. Default value: true.
  new_nat_gateway           = true
  # The ECS instance types of the worker nodes.
  worker_instance_types     = [data.alicloud_instance_types.default.instance_types[0].id]
  # The total number of worker nodes in the Kubernetes cluster. Default value: 3. Maximum value: 50.
  worker_number             = 2
  # The password that is used to log on to the nodes through SSH.
  password                  = "Yourpassword1234"
  # The CIDR block of the pods. When cluster_network_type is set to flannel, you must set this parameter. It cannot be the same as the CIDR block of the VPC or the CIDR blocks of the Kubernetes clusters in the VPC. It cannot be modified after the cluster is created. Maximum number of hosts in the cluster: 256.
  pod_cidr                  = "172.20.0.0/16"
  # The CIDR block of the Services. It cannot be the same as the CIDR block of the VPC or the CIDR blocks of the Kubernetes clusters in the VPC. It cannot be modified after the cluster is created.
  service_cidr              = "172.21.0.0/20"
  # Specify whether to install the Cloud Monitor agent on nodes.
  install_cloud_monitor     = true
  # Specify whether to create an Internet-facing Server Load Balancer (SLB) instance for the API server. Default value: false.
  slb_internet_enabled      = true
  # The type of the system disks for worker nodes. Valid values: cloud_ssd and cloud_efficiency. Default value: cloud_efficiency.
  worker_disk_category      = "cloud_efficiency"
  # The type of the data disks for worker nodes. Valid values: cloud_ssd and cloud_efficiency. If you do not specify this parameter, no data disk will be created.
  worker_data_disk_category = "cloud_ssd"
  # The size of each data disk for each worker node. Valid values: 20 to 32768. Unit: GB. Default value: 40.
  worker_data_disk_size     = 200
  # Logging configuration.
  addons {
    name     = "logtail-ds"
    config   = "{\"IngressDashboardEnabled\":\"true\",\"sls_project_name\":alicloud_log_project.log.name}"
  }
}

resource "alicloud_cs_kubernetes_node_pool" "at1" {
  cluster_id                   = alicloud_cs_managed_kubernetes.default.0.id
  name                         = local.k8s_name
  vswitch_ids        = split(",", join(",", alicloud_vswitch.vswitches. *.id))
  instance_types               = [data.alicloud_instance_types.default.instance_types[0].id]
password                  = "Yourpassword1234"
  scaling_config {
    min_size     = 3
    max_size     = 5
  }

}