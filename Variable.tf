variable "region" {
  description = "The Alibaba Cloud region you will use (defaults to Beijing)"
  default     = "ap-southeast-1"
}

variable "as" {
  description = "Autoscaling group"
  default     = "autoscaling"
}

variable "name" {
  default = "auto_provisioning_group"
}
 
variable "dbname" {
  default = "jawndb"
}
 
variable "k8sname" {
  default = "myk8s"
}