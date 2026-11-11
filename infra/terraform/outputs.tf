output "resource_group_name" {
  description = "Resource group del reto"
  value       = azurerm_resource_group.main.name
}

output "cluster_name" {
  description = "Nombre del cluster AKS"
  value       = azurerm_kubernetes_cluster.main.name
}

output "acr_name" {
  description = "Nombre del ACR"
  value       = azurerm_container_registry.main.name
}

output "acr_login_server" {
  description = "Servidor del ACR para docker login y para las imagenes"
  value       = azurerm_container_registry.main.login_server
}
