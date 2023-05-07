variable "proxmox_url" {
  type = string
}

variable "proxmox_username" {
  type = string
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

variable "proxmox_node" {
  type    = string
  default = "pve"
}

variable "proxmox_bridge" {
  type        = string
  description = "Proxmox Bridge Interface for Packer Builds"
  default     = "vmbr1"
}

variable "iso_url" {
  type        = string
  description = "ISO file URL"
  default     = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-11.7.0-amd64-netinst.iso"
}

variable "iso_checksum" {
  type        = string
  description = "ISO file checksum"
  default     = "4460ef6470f6d8ae193c268e213d33a6a5a0da90c2d30c1024784faa4e4473f0c9b546a41e2d34c43fbbd43542ae4fb93cfd5cb6ac9b88a476f1a6877c478674"
}

variable "vm_id" {
  type        = number
  default     = 9000
  description = "ID of temp VM during build process"
}

variable "vm_name" {
  type        = string
  description = "VM name"
  default     = "base"
}

variable "cores" {
  type        = number
  description = "Number of cores"
  default     = 1
}

variable "sockets" {
  type        = number
  description = "Number of sockets"
  default     = 1
}

variable "memory" {
  type        = number
  description = "Memory in MB"
  default     = 1024
}

variable "root_password" {
  type        = string
  description = "Root password"
  default     = "vagrant"
}

variable "ssh_username" {
  type        = string
  description = "SSH username"
  default     = "debian"
}

variable "ssh_password" {
  type        = string
  description = "SSH password"
  default     = "vagrant"
}

variable "ssh_public_key_path" {
  type        = string
  description = "SSH Public Key Path"
  default     = "~/.ssh/vagrant.pub"
}

variable "ssh_private_key_path" {
  type        = string
  description = "SSH Private Key Path"
  default     = "~/.ssh/vagrant"
}

variable "vm_ip" {
  type        = string
  description = "IP Address of Packer Build VM"
}

variable "vm_netmask" {
  type        = string
  description = "Subnet Mask for Packer Build VM"
}

variable "vm_gateway" {
  type        = string
  description = "Gateway for Packer Build VM"
}

variable "vm_nameserver" {
  type        = string
  description = "DNS Resolver for Packer Build VM"
}

variable "cloud_init_storage_pool" {
  type        = string
  description = "Proxmox Storage Pool for cloud-init Volumes"
  default     = "volumes"
}

variable "disk_storage_pool" {
  type        = string
  description = "Proxmox Storage Pool for disk/template Volumes"
  default     = "volumes"
}
