 resource "alicloud_db_instance" "instance" {
  engine           = "MySQL"
  engine_version   = "5.6"
  instance_type    = "rds.mysql.s1.small"
  instance_storage = "10"
  vswitch_id       = alicloud_vswitch.vswitch.id
  instance_name    = var.dbname
 }

 resource "alicloud_db_database" "default" {
  instance_id = alicloud_db_instance.instance.id
  name        = "tftestdatabase"
 }