# Create a new ECS instance for a VPC
resource "alicloud_security_group" "group" {
  name        = "tf_test_foo"
  description = "foo"
  vpc_id      = alicloud_vpc.default.id
}
