
resource "null_resource" "create-service-instance" {
    provisioner "local-exec" {
        command = "ibmcloud dns instance-create ${var.dns_service_instance_name} free --output json | jq .id > ${data.template_file.service-id.rendered}"
    }
}

resource "null_resource" "delete-service-instance" {
    depends_on = [null_resource.create-service-instance]

    triggers = {
        service_id = local.service_id
        id_file = local.id_file
        zone_id = local.zone_id
        zone_file =  local.zone_file
        network_id =  local.network_id
        network_file = local.network_file
        crn_file = local.crn_file

    }
    lifecycle {
        ignore_changes = [
            triggers["service_id"],
            triggers["id_file"],
            triggers["zone_id"],
            triggers["zone_file"],
            triggers["network_id"],
            triggers["network_file"],
            triggers["crn_file"]
        ]
    }

    provisioner "local-exec" {
        when = destroy
        //This is the only way to provide multi line command
        command = <<EOT
        echo 'Remove network'
        ibmcloud dns permitted-network-remove --force ${self.triggers.zone_id} ${self.triggers.network_id}
        rm -f ${self.triggers.network_file}
        echo 'Destroying zone'
        ibmcloud dns zone-delete --force ${self.triggers.zone_id}
        rm -f ${self.triggers.zone_file}
        echo 'Destroying the instance'
        ibmcloud dns instance-delete --force ${self.triggers.service_id}
        rm -f ${self.triggers.id_file}
        rm -f ${self.triggers.crn_file}
        EOT
    }
}

resource "null_resource" "set-instance-target"{



    provisioner "local-exec" {
        //command = "ibmcloud dns instance-target ${data.local_file.read-service-id.content}"
        command = "ibmcloud dns instance-target ${local.service_id}"
    }
}


resource "null_resource" "create-zone"{

    depends_on = [null_resource.set-instance-target]

    provisioner "local-exec" {
        command = "ibmcloud dns zone-create ${var.dns_zone} --output json | jq .id > ${data.template_file.zone-id.rendered}"
    }
}

//This ensures explict wait on the availability of vpc_id
resource "null_resource" "module_depends_on_vpc_id" {

    triggers = {
        value = "${length(var.vpc_id)}"
    }
}

resource "null_resource" "vpc-crn"{
    depends_on = [null_resource.module_depends_on_vpc_id]
    provisioner "local-exec" {
        command = "ibmcloud is vpc ${var.vpc_id} --json | jq .crn > ${data.template_file.vpc-crn-id.rendered}"
    }

}

resource "null_resource" "add-network"{
    depends_on = [null_resource.vpc-crn]
    provisioner "local-exec" {
         command = "ibmcloud dns permitted-network-add ${local.zone_id} --type vpc --vpc-crn ${local.vpc_crn_id} --output json | jq .id > ${data.template_file.network-id.rendered}"
    }
}

locals {
    //The rendered data has newline and not using trimspace will result in bash command failure

    service_id = trimspace(data.local_file.read-service-id.content)
    id_file = data.template_file.service-id.rendered
    zone_id = trimspace(data.local_file.read-zone-id.content)
    zone_file = data.template_file.zone-id.rendered
    network_id = trimspace(data.local_file.read-network-id.content)
    network_file = data.template_file.network-id.rendered
    vpc_crn_id = trimspace(data.local_file.read-vpc-crn-id.content)
    crn_file = data.template_file.vpc-crn-id.rendered


}


# ---------------------------Data Rendering----------
data "template_file" "service-id"{
  template = "${path.module}/id.log"
}


data "local_file" "read-service-id"{
  filename   = data.template_file.service-id.rendered
  depends_on = [null_resource.create-service-instance]
}


data "template_file" "zone-id"{
  template = "${path.module}/zone.log"
}

data "local_file" "read-zone-id"{
  filename   = data.template_file.zone-id.rendered
  depends_on = [null_resource.create-zone]
}

data "template_file" "vpc-crn-id"{
  template = "${path.module}/crn.log"
}

data "local_file" "read-vpc-crn-id"{
  filename   = data.template_file.vpc-crn-id.rendered
  depends_on = [null_resource.vpc-crn]
}

data "template_file" "network-id"{
  template = "${path.module}/net.log"
}


data "local_file" "read-network-id"{
  filename   = data.template_file.network-id.rendered
  depends_on = [null_resource.add-network]
}