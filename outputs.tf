#########################################################
## Outputs
#########################################################

output "vm_id" {
  value = module.ubuntuvm.vm_id_output
}

output "vm_name" {
  value = module.ubuntuvm.vm_name
}

output "vm_private_ip_address" {
  value = module.ubuntuvm.vm_private_ip_address
}

output "vm_public_ip_address" {
  value = module.ubuntuvm.vm_public_ip_address
}