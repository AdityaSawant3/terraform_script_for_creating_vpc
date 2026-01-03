variable "region" {
    type = string
}

variable "ami" {
    type = string
}
variable "access_key" {
    type = string
}
variable "secret_key" {
    type = string
}
variable "instance_type" {
    type = string
}

variable "vpc_cidr_block" {
    type = string
}
variable "instance_tenancy" {
    type = string
}

variable "public_subnet_cidr_block" {
    type = string
}
variable "private_subnet_cidr_block" {
    type = string
}

variable "internet_access" {
    type = string
}

variable "ssh_key" {
    type = string
}
variable "my_ip" {
    type = string
}
