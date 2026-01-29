output "vpc_id" {
  value = module.vpc.vpc_id
}

output "application_public_ip" {
  value = module.application_instance.public_ip
}

output "inspection_instance_id" {
  value = module.inspection_instance.id
}

output "application_instance_id" {
  value = module.application_instance.id
}

output "inspection_eni_id" {
  value = module.inspection_instance.primary_network_interface_id
}
