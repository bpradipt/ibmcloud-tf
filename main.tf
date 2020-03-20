provider "ibm" {
  ibmcloud_api_key   = var.ibmcloud_api_key
  generation         = 2
  region             = var.ibmcloud_region
}


module "vpc" {
  source = "./vpc"
}
