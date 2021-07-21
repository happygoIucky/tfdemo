provider "alicloud" {
  access_key = "enter your access key"
  secret_key = "enter your secret key"
  region = var.region
}

data "alicloud_zones" "default" {
  available_disk_category     = "cloud_efficiency"
  available_resource_creation = "VSwitch"
}

# Create a new ECS instance for VPC
resource "alicloud_vpc" "default" {
  vpc_name   = var.name
  cidr_block = "172.16.0.0/16"
}

resource "alicloud_vswitch" "vswitch" {
  vpc_id            = alicloud_vpc.default.id
  cidr_block        = "172.16.0.0/24"
  zone_id           = data.alicloud_zones.default.zones[0].id
  vswitch_name      = var.name
}

data "alicloud_instance_types" "default" {
  availability_zone = data.alicloud_zones.default.zones[0].id
  cpu_core_count    = 2 
  memory_size       = 4
  # instance_type       = "ecs.c5.xlarge" -> this is not supported, specify the core/ram
}

data "alicloud_images" "default" {
  name_regex  = "^ubuntu_18.*64"
  most_recent = true
  owners      = "system"
}
resource "alicloud_slb_load_balancer" "slb" {
  load_balancer_name       = "test-slb-tf"
  load_balancer_spec       = "slb.s2.small"
  vswitch_id = alicloud_vswitch.vswitch.id

}
resource "alicloud_ess_scaling_group" "default" {
  min_size           = 2
  max_size           = 3
  scaling_group_name = var.name
  removal_policies   = ["OldestInstance", "NewestInstance"]
  vswitch_ids        = [alicloud_vswitch.vswitch.id]
}

# creation of ECS Instance
# resource "alicloud_instance" "instance" {
# Singapore Region
# availability_zone = "ap-southeast-1a"
# security_groups   = alicloud_security_group.group.*.id 
#  instance_type              = "ecs.c5.xlarge"
#  system_disk_category       = "cloud_efficiency"
#  system_disk_name           = "test_foo_system_disk_name"
#  system_disk_description    = "test_foo_system_disk_description"
#  image_id                   = data.alicloud_images.default.images[0].id
#  instance_name              = "test_foo"
#  vswitch_id                 = alicloud_vswitch.vswitch.id
#  internet_max_bandwidth_out = 10
#  data_disks {
#    name        = "disk2"
#    size        = 20
#    category    = "cloud_efficiency"
#    description = "disk2"
#    encrypted   = true
#    kms_key_id  = alicloud_kms_key.key.id
#  }
# }

resource "alicloud_ess_scaling_configuration" "default" {
  scaling_group_id  = alicloud_ess_scaling_group.default.id
  image_id          = data.alicloud_images.default.images[0].id
  instance_type     = data.alicloud_instance_types.default.instance_types[0].id
  security_group_id = alicloud_security_group.group.id
  force_delete      = true
  active            = true
  # enable           = true
}