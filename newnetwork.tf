# Specificeer de versie van Terraform die je gebruikt
terraform {
    required_version = ">= 1.0"
    required_providers {
        vcd = {
            source  = "vmware/vcd"
            version = "~> 3.0"
        }
    }
}

# Provider configuratie
provider "vcd" {
    user     = "your-user"
    password = "your-pass"
    org      = "your-org
    url      = "your-url"
    vdc      = "your-vdc"
}
##########################################################################################################
# Data bronnen voor catalogus en media
data "vcd_catalog" "test2" {
    name = "test2"
}
##########################################################################################################
data "vcd_catalog_media" "debian-iso" {
    catalog_id = data.vcd_catalog.test2.id
    name       = "debian-12.7.0-amd64-DVD-1.iso"
}
##########################################################################################################
data "vcd_catalog_media" "windows-iso" {
    catalog_id = data.vcd_catalog.test2.id
    name       = "20348.1.210507-1500.fe_release_amd64fre_SERVER_LOF_PACKAGES_OEM.iso"
}
##########################################################################################################
# Resource voor vApp
resource "vcd_vapp" "stage-vapp2" {
    name        = "DATABASE"
    power_on    = false
    description = "Stage vApp voor testen"
}
##########################################################################################################
resource "vcd_vapp_org_network" "stage-vapp2-network" {
    vapp_name        = vcd_vapp.stage-vapp2.name
    org_network_name = "stage-router"
}
##########################################################################################################
# Variabelen voor schijven
variable "disk_countWin" {
    description = "Aantal schijven om uit te rollen"
    default     = 2
}
##########################################################################################################
variable "disk_namesWin" {
    description = "Een lijst met schijf namen voor Windows"
    type        = list(string)
    default     = ["Win-disk1", "Win-disk2"]
}
##########################################################################################################
variable "disk_countLin" {
    description = "Aantal schijven om uit te rollen"
    default     = 3
}
##########################################################################################################
variable "disk_namesLin" {
    description = "Een lijst met schijf namen voor Linux"
    type        = list(string)
    default     = ["linux-disk1", "linux-disk2", "linux-disk3"]
}
##########################################################################################################
# Resources voor onafhankelijke schijven
resource "vcd_independent_disk" "Win-disk" {
    count      = var.disk_countWin
    name       = var.disk_namesWin[count.index]
    size_in_mb = "16384"
}
##########################################################################################################
resource "vcd_independent_disk" "Lin-disk" {
    count      = var.disk_countLin
    name       = var.disk_namesLin[count.index]
    size_in_mb = "16384"
}
##########################################################################################################
# Variabelen voor VM's
variable "vm_countWin" {
    description = "Aantal Windows VM's om uit te rollen"
    default     = 2
}
##########################################################################################################
variable "vm_namesWin" {
    description = "Een lijst met Windows VM-namen"
    type        = list(string)
    default     = ["Win-vm-1", "Win-vm-2"]
}
##########################################################################################################
variable "vm_countLin" {
    description = "Aantal Linux VM's om uit te rollen"
    default     = 3
}
##########################################################################################################
variable "vm_namesLin" {
    description = "Een lijst met Linux VM-namen"
    type        = list(string)
    default     = ["Lin-vm-1", "Lin-vm-2", "Lin-vm-3"]
}
##########################################################################################################
# Resources voor VM's in de vApp
resource "vcd_vapp_vm" "Windows" {
    count          = var.vm_countWin
    vapp_name      = vcd_vapp.stage-vapp2.name
    name           = var.vm_namesWin[count.index]
    computer_name  = var.vm_namesWin[count.index]
    memory         = 2048
    cpus           = 4
    cpu_cores      = 2
    firmware       = "bios"
    description    = "Stage VM voor testen"
    os_type        = "windows2019srv_64Guest"
    hardware_version = "vmx-19"
    boot_image_id  = data.vcd_catalog_media.windows-iso.id

    network {
        type               = "org"
        name               = "stage-router"
        ip_allocation_mode = "DHCP"
    }

    disk {
        name        = var.disk_namesWin[count.index]
        bus_number  = 1
        unit_number = 0
    }
}




##########################################################################################################
resource "vcd_vapp_vm" "Linux" {
    count          = var.vm_countLin
    vapp_name      = vcd_vapp.stage-vapp2.name
    name           = var.vm_namesLin[count.index]
    computer_name  = var.vm_namesLin[count.index]
    memory         = 2048
    cpus           = 2
    cpu_cores      = 1
    firmware       = "efi"
    os_type        = "debian11_64Guest"
    hardware_version = "vmx-19"
    boot_image_id  = data.vcd_catalog_media.debian-iso.id

    network {
        type               = "org"
        name               = "stage-router"
        ip_allocation_mode = "DHCP"
    }

    disk {
        name        = var.disk_namesLin[count.index]
        bus_number  = 1
        unit_number = 0
    }
    
}

##########################################################################################################
