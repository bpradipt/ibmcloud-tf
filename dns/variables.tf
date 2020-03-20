
variable "vpc_id" {
    description = "VPC ID to connect the DNS service"
}


variable "dns_zone" {
    description = "DNS zone"
    default = "bpradipt.ocp.com"
}

variable "dns_service_instance_name" {
    description = "DNS service instance"
    default = "bpradipt-dns"
}
