locals {
     BASENAME = "bpradipt"
     ZONE     = "us-south-1"
   }

resource ibm_is_vpc "vpc" {
  name = "${local.BASENAME}-vpc"
}
