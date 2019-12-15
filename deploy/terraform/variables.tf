variable "region" {
  default = "us-east-1"
}

variable "amis" {
  type = "map"
  default = {
    "us-east-1" = "ami-0b69ea66ff7391e80"
    "us-east-2" = "ami-00c03f7f7f2ec15c3"
  }
}