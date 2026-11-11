variable "location" {
  description = "Region de Azure donde se crean los recursos"
  type        = string
  default     = "eastus2"
}

variable "resource_group_name" {
  description = "Resource group que contiene el AKS y el ACR"
  type        = string
  default     = "rg-mbco-reto"
}

variable "cluster_name" {
  description = "Nombre del cluster AKS"
  type        = string
  default     = "aks-mbco-reto"
}

variable "acr_name" {
  description = "Nombre del ACR: unico en Azure, solo letras minusculas y numeros"
  type        = string
  default     = "acrmbcoreto"
}

variable "node_count" {
  description = "Cantidad de nodos del cluster"
  type        = number
  default     = 1
}

variable "node_vm_size" {
  description = "Tamano de la VM de cada nodo"
  type        = string
  default     = "Standard_B2s"
}

variable "tags" {
  description = "Etiquetas comunes para todos los recursos"
  type        = map(string)
  default = {
    proyecto = "mbco-reto"
    gestion  = "terraform"
  }
}
