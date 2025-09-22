provider "aws" {
  region = var.region
}


resource "aws_instance" "up-server-0412" {
  ami           = var.ami_id
  instance_type = var.instancetypes
  count         = var.instance_count
  #key_name      = var.key_pair
}