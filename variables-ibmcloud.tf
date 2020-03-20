variable "ibmcloud_api_key" {
    description = "IBM CLOUD API KEY"
}

variable "ibmcloud_region" {
  type = string
  description = "The target IBMCloud region for the cluster."
  default = "us-south"
}
