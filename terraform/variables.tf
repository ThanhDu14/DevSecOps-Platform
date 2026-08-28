variable "project_id" {
  description = "The GCP Project ID"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone to deploy resources"
  type        = string
  default     = "us-central1-a"
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "devsecops-vpc"
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "devsecops-subnet"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "ssh_public_key" {
  description = "The public SSH key to inject into VMs"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "devsecops-gke"
}

variable "iap_client_id" {
  description = "OAuth Client ID for Identity-Aware Proxy"
  type        = string
}

variable "iap_client_secret" {
  description = "OAuth Client Secret for Identity-Aware Proxy"
  type        = string
  sensitive   = true
}
