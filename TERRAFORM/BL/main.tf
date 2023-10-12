############## KONFIGURACJA TERRAFORM #####################
# Azure Provider i jego wersja 
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.75.0"
    }
  }
}

# Konfiguracja Providera
provider "azurerm" {
  features {}
}
############## KONFIGURACJA TERRAFORM ######################




#################### WSTEPNA KONFIGURACJA AZURE #####################################
# Tworzymy RG
resource "azurerm_resource_group" "BL-RG" {
  name     = "BL-resources"
  location = "West Europe"
  tags = {
    enviroment = "BLACKLAN"
  }
}

# Tworzymy VNET

resource "azurerm_virtual_network" "BL-VNET" {
  name                = "BL-network"
  resource_group_name = azurerm_resource_group.BL-RG.name
  location            = azurerm_resource_group.BL-RG.location
  address_space       = ["10.199.0.0/16"]

  tags = {
    enviroment = "BLACKLAN"
  }
}

#Tworzymy SUBNET

resource "azurerm_subnet" "BL-SNET" {
  name                 = "BL-subnet"
  resource_group_name  = azurerm_resource_group.BL-RG.name
  virtual_network_name = azurerm_virtual_network.BL-VNET.name
  address_prefixes     = ["10.199.1.0/24"]

}

resource "azurerm_subnet" "VW-SNET" {
  name                 = "VW-subnet"
  resource_group_name  = azurerm_resource_group.BL-RG.name
  virtual_network_name = azurerm_virtual_network.BL-VNET.name
  address_prefixes     = ["10.199.2.0/24"]

}

# Tworzymy NSG

resource "azurerm_network_security_group" "BL-NSG" {
  name                = "BL-NSG"
  location            = azurerm_resource_group.BL-RG.location
  resource_group_name = azurerm_resource_group.BL-RG.name

  security_rule {
    name                       = "ALL"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


  tags = {
    enviroment = "BLACKLAN"
  }

}
# ŁAczymy subnet z NSG

resource "azurerm_subnet_network_security_group_association" "BL-NSGA" {
  subnet_id                 = azurerm_subnet.BL-SNET.id
  network_security_group_id = azurerm_network_security_group.BL-NSG.id
}
#################### WSTEPNA KONFIGURACJA AZURE #####################################

#################### VM #####################################
# Publick IP-VM

resource "azurerm_public_ip" "PI-VM1" {
  name                = "Public-IP-VM1"
  resource_group_name = azurerm_resource_group.BL-RG.name
  location            = azurerm_resource_group.BL-RG.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "BLACKLAN"
  }
}

# Publick IP-VWAN1

resource "azurerm_public_ip" "PI-VWAN1" {
  name                = "Public-IP-VWAN1"
  resource_group_name = azurerm_resource_group.BL-RG.name
  location            = azurerm_resource_group.BL-RG.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "BLACKLAN"
  }
}



# NIC dla VM1

resource "azurerm_network_interface" "VM1-NIC" {
  name                = "VM1-NIC"
  location            = azurerm_resource_group.BL-RG.location
  resource_group_name = azurerm_resource_group.BL-RG.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.BL-SNET.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.PI-VM1.id
  }
  tags = {
    environment = "BLACKLAN"
  }

}

# VM1


resource "azurerm_linux_virtual_machine" "VM1" {
  name                            = "VM1-UBUNTU"
  resource_group_name             = azurerm_resource_group.BL-RG.name
  location                        = azurerm_resource_group.BL-RG.location
  size                            = "Standard_B1Is"
  admin_username                  = "mszczechla"
  admin_password                  = "Makofinal10!!"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.VM1-NIC.id,
  ]


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  tags = {
    environment = "BLACKLAN"
  }
}

# AUTO SHUTDOWN 

resource "azurerm_dev_test_global_vm_shutdown_schedule" "AUTO-SHUT" {
  virtual_machine_id = azurerm_linux_virtual_machine.VM1.id
  location           = azurerm_resource_group.BL-RG.location
  enabled            = true

  daily_recurrence_time = "2200"
  timezone              = "Central European Standard Time"

  notification_settings {
    enabled         = true
    time_in_minutes = "60"
  }
}
#################### VM #####################################



#################### VIRTUAL WAN  #####################################

# # VVWAN

# resource "azurerm_virtual_wan" "VWAN" {
#   name                = "VIRTUAl-van"
#   resource_group_name = azurerm_resource_group.BL-RG.name
#   location            = azurerm_resource_group.BL-RG.location

#   tags = {
#     environment = "BLACKLAN"
#   }

# }

# # VWAN HUB

# resource "azurerm_virtual_hub" "VW-HUB1" {
#   name                   = "VW-HUB1"
#   resource_group_name    = azurerm_resource_group.BL-RG.name
#   location               = azurerm_resource_group.BL-RG.location
#   virtual_wan_id         = azurerm_virtual_wan.VWAN.id
#   address_prefix         = "10.199.0.0/16"
#   sku                    = "Standard"
#   hub_routing_preference = "VpnGateway"

#   tags = {
#     environment = "BLACKLAN"
#   }

# }

# # VPN GATEWAY

# resource "azurerm_vpn_gateway" "VPN-GW" {
#   name                = "VPN-GW"
#   location            = azurerm_resource_group.BL-RG.location
#   resource_group_name = azurerm_resource_group.BL-RG.name
#   virtual_hub_id      = azurerm_virtual_hub.VW-HUB1.id

#   tags = {
#     environment = "BLACKLAN"
#   }



# }

# # VPN Site

# resource "azurerm_vpn_site" "VPN-SITE" {
#   name                = "VPN-SITE"
#   location            = azurerm_resource_group.BL-RG.location
#   resource_group_name = azurerm_resource_group.BL-RG.name
#   virtual_wan_id      = azurerm_virtual_wan.VWAN.id
#   address_cidrs       = ["10.0.0.0/8"]
#   link {
#     name       = "CISRT1003"
#     ip_address = "85.219.208.212"
#     bgp {
#       asn             = "65000"
#       peering_address = "10.0.0.9"
#     }
#   }



# }

# # VPN Connection

# resource "azurerm_vpn_gateway_connection" "VPN-CON" {
#   name               = "VPN-CONNECTION"
#   vpn_gateway_id     = azurerm_vpn_gateway.VPN-GW.id
#   remote_vpn_site_id = azurerm_vpn_site.VPN-SITE.id

#   vpn_link {
#     name             = "link1"
#     vpn_site_link_id = azurerm_vpn_site.VPN-SITE.link[0].id
#   }

# }