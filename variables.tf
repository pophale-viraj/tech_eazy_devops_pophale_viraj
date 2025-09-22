variable "ami_id" {
  type = string
}

variable "instancetypes" {
  type    = string
  default = "t2.medium"
}

variable "instance_count" {
  type = number
}

variable "region" {
  type = string
}

/* variable "key_pair" {
  type = string
} */