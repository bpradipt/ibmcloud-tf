provider "ibm" {
  ibmcloud_api_key   = var.ibmcloud_api_key
  generation         = 2
  region             = var.ibmcloud_region
}


module "vpc" {
  source = "./vpc"
}

module "dns" {
  source = "./dns"
  vpc_id = module.vpc.vpc_id
}
