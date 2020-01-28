# Modèle de VM Linux dans Azure 

# Azure Resource Group
resource "azurerm_resource_group" "Terra-RG-Stan1" {
  name     = var.ResourceGroupName
  location = var.AzureRegion
}

# Azure VNet
resource "azurerm_virtual_network" "Terra-VNet-Stan1" {
  name                = var.VNetName
  address_space       = ["10.0.0.0/16"]
  location            = var.AzureRegion
  resource_group_name = azurerm_resource_group.Terra-RG-Stan1.name
}

# Subnet inside Azure VNet
resource "azurerm_subnet" "Terra-Subnet-Stan1" {
  name                 = "Subnet-Stan1"
  resource_group_name  = azurerm_resource_group.Terra-RG-Stan1.name
  virtual_network_name = azurerm_virtual_network.Terra-VNet-Stan1.name
  address_prefix       = "10.0.2.0/24"
}

# Network Security Group
resource "azurerm_network_security_group" "NSG-Stan1" {
  name                = var.NSGName
  location            = var.AzureRegion
  resource_group_name = azurerm_resource_group.Terra-RG-Stan1.name
  # Allow SSH in
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  # Allow HTTP in
  security_rule {
    name                       = "Allow-Http"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


# Public IP Adress used to connect directly VM
resource "azurerm_public_ip" "PublicIP-Stan1" {
   count                   = var.NumberOfVM
   name = "${var.PublicIPName}-${count.index}"
   resource_group_name = azurerm_resource_group.Terra-RG-Stan1.name
   allocation_method = var.PublicIPAllocationType
   location = var.AzureRegion
}

# NIC VM attached to Subnet
resource "azurerm_network_interface" "Terra-NIC-Stan1" {
  count               = var.NumberOfVM
  name                = "${var.NicName}-${count.index}"
  location            = var.AzureRegion
  resource_group_name = azurerm_resource_group.Terra-RG-Stan1.name
  network_security_group_id = azurerm_network_security_group.NSG-Stan1.id

  ip_configuration {
    name                          = "Stan1-ipconfiguration"
    subnet_id                     = azurerm_subnet.Terra-Subnet-Stan1.id
    private_ip_address_allocation = var.PrivateIPAdressAllocationType
    public_ip_address_id = element(azurerm_public_ip.PublicIP-Stan1.*.id, count.index)  
  }
}

# Azure Managed Disk - Additional Data Disk for the VM - disque 1 data
resource "azurerm_managed_disk" "Terra-ManagedDisk-Stan1" {
  count                = var.NumberOfVM
  name                 = "${var.DataDiskName}-${count.index}"
  location             = var.AzureRegion
  resource_group_name  = azurerm_resource_group.Terra-RG-Stan1.name
  storage_account_type = var.DataDisk-StorageType
  create_option        = "Empty"
  disk_size_gb         = var.DataDiskStorageSize
}

# Azure Availabity Set
resource "azurerm_availability_set" "Terra-AvailabilitySet-Stan1" {
   name = var.AvailabilitySetName
   resource_group_name = azurerm_resource_group.Terra-RG-Stan1.name
   location = var.AzureRegion
   managed = true  # necessary if you use managed disks
   platform_fault_domain_count = 3   # by default it is 3 but in some region like France Central it can be 2
}

# Azure VM
resource "azurerm_virtual_machine" "Terra-VM-Stan1" {
  count                 = var.NumberOfVM
  name                  = "${var.VMName}-${count.index}"
  location              = var.AzureRegion
  resource_group_name   = azurerm_resource_group.Terra-RG-Stan1.name
  network_interface_ids = [element(azurerm_network_interface.Terra-NIC-Stan1.*.id, count.index)]
  vm_size               = var.VMSize
  availability_set_id   = azurerm_availability_set.Terra-AvailabilitySet-Stan1.id
  # explicit dependency to be sure that necessary resources are already created
  depends_on = [azurerm_network_interface.Terra-NIC-Stan1,azurerm_managed_disk.Terra-ManagedDisk-Stan1]

  storage_image_reference {
    publisher = var.OSPublisher
    offer     = var.OSOffer
    sku       = var.OSsku
    version   = var.OSversion
  }

  storage_os_disk {
    name              = "${var.OSDiskName}-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = var.OSDisk-StorageType
  }

  storage_data_disk {
    name            = element(azurerm_managed_disk.Terra-ManagedDisk-Stan1.*.name, count.index)
    managed_disk_id = element(azurerm_managed_disk.Terra-ManagedDisk-Stan1.*.id, count.index)
    create_option   = "Attach"
    lun             = 0
    disk_size_gb    = element(azurerm_managed_disk.Terra-ManagedDisk-Stan1.*.disk_size_gb, count.index)
  }

  os_profile {
    computer_name  = "${var.VMName}-${count.index}"
    admin_username = var.AdminName
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.AdminName}/.ssh/authorized_keys"
      key_data = data.azurerm_key_vault_secret.Terra-Datasource-cleSSH.value
    } 
  }

  tags = {
    environment = var.TagEnvironment
    usage       = var.TagUsage
  }
}
