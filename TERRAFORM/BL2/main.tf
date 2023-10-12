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

#################### PUBLICK IPs  #####################################
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



#################### PUBLICK IPs  #####################################

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

#################### VM #####################################


# VM1


resource "azurerm_linux_virtual_machine" "VM1" {
  name                            = "VM1-UBUNTU"
  resource_group_name             = azurerm_resource_group.BL-RG.name
  location                        = azurerm_resource_group.BL-RG.location
  size                            = "Standard_B1ls"
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
    email           = "maciejszczechla@gmail.com"
  }
}
#################### VM #####################################



#################### VIRTUAL WAN  #####################################

#Tworzymy SUBNET


resource "azurerm_subnet" "VW-SNET" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.BL-RG.name
  virtual_network_name = azurerm_virtual_network.BL-VNET.name
  address_prefixes     = ["10.199.2.0/24"]

}

# Publick IP-VWAN0

resource "azurerm_public_ip" "Pip_instance_0" {
  name                = "Pip_instance_0"
  resource_group_name = azurerm_resource_group.BL-RG.name
  location            = azurerm_resource_group.BL-RG.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "BLACKLAN"
  }
}

# Publick IP-VWAN1

resource "azurerm_public_ip" "Pip_instance_1" {
  name                = "Pip_instance_1"
  resource_group_name = azurerm_resource_group.BL-RG.name
  location            = azurerm_resource_group.BL-RG.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "BLACKLAN"
  }
}


# VVWAN

resource "azurerm_virtual_wan" "VWAN" {
  name                = "VIRTUAl-van"
  resource_group_name = azurerm_resource_group.BL-RG.name
  location            = azurerm_resource_group.BL-RG.location

  tags = {
    environment = "BLACKLAN"
  }

}

# VWAN HUB

resource "azurerm_virtual_hub" "VW-HUB1" {
  name                   = "VW-HUB1"
  resource_group_name    = azurerm_resource_group.BL-RG.name
  location               = azurerm_resource_group.BL-RG.location
  virtual_wan_id         = azurerm_virtual_wan.VWAN.id
  address_prefix         = "10.199.0.0/16"
  sku                    = "Standard"
  hub_routing_preference = "VpnGateway"

  tags = {
    environment = "BLACKLAN"
  }

}

#VPN-SITE

resource "azurerm_vpn_site" "VPN-SITE" {
  name                = "VPN-SITE"
  location            = azurerm_resource_group.BL-RG.location
  resource_group_name = azurerm_resource_group.BL-RG.name
  virtual_wan_id      = azurerm_virtual_wan.VWAN.id
  address_cidrs       = ["10.0.0.0/8"]
  link {
    name       = "CISRT1003"
    ip_address = "85.219.208.212"
    bgp {
      asn             = "65000"
      peering_address = "10.0.0.9"

    }
  }
  link {
    name       = "FORFW1001"
    ip_address = "85.219.208.241"
    bgp {
      asn             = "64911"
      peering_address = "10.0.0.4"

    }
  }


}


# Virtual network gateway

resource "azurerm_virtual_network_gateway" "gateway" {
  name                = "VN-GW"
  location            = azurerm_resource_group.BL-RG.location
  resource_group_name = azurerm_resource_group.BL-RG.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = true
  enable_bgp    = true
  sku           = "VpnGw2"
  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.Pip_instance_0.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.VW-SNET.id
  }
  ip_configuration {
    name                          = "vnetGatewayConfig2"
    public_ip_address_id          = azurerm_public_ip.Pip_instance_1.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.VW-SNET.id
  }
  bgp_settings {
    asn = "65515"
  }
}

# Virtual local network gateway

resource "azurerm_local_network_gateway" "LNG-CISRT1003" {
  name                = "LNG-CISRT1003"
  resource_group_name = azurerm_resource_group.BL-RG.name
  location            = azurerm_resource_group.BL-RG.location
  gateway_address     = "85.219.208.212"
  address_space       = ["10.0.0.0/8"]
  bgp_settings {
    asn                 = "65000"
    bgp_peering_address = "10.0.0.9"
  }
}


resource "azurerm_local_network_gateway" "LNG-FORFW1001" {
  name                = "LNG-FORFW1001"
  resource_group_name = azurerm_resource_group.BL-RG.name
  location            = azurerm_resource_group.BL-RG.location
  gateway_address     = "85.219.208.241"
  address_space       = ["10.0.0.0/8"]
  bgp_settings {
    asn                 = "64911"
    bgp_peering_address = "10.0.0.4"
  }
}


# Connection 

resource "azurerm_virtual_network_gateway_connection" "AZ-CISRT1003" {
  name                = "AZ-CISRT1003"
  location            = azurerm_resource_group.BL-RG.location
  resource_group_name = azurerm_resource_group.BL-RG.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.LNG-CISRT1003.id
  enable_bgp                 = true
  shared_key                 = "123456789"
  ipsec_policy {
    dh_group         = "DHGroup14" #phase1
    ike_encryption   = "AES256"    #phase2
    ike_integrity    = "SHA256"    #phase2
    ipsec_encryption = "AES256"    #phase1
    ipsec_integrity  = "SHA256"    #phase1
    pfs_group        = "ECP256"    #phase2 DH19
    sa_datasize      = "102400000"
    sa_lifetime      = "27000"

  }

}

resource "azurerm_virtual_network_gateway_connection" "AZ-FORFW1001" {
  name                = "AZ-FORFW1001"
  location            = azurerm_resource_group.BL-RG.location
  resource_group_name = azurerm_resource_group.BL-RG.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.LNG-FORFW1001.id
  enable_bgp                 = true
  shared_key                 = "123456789"
  ipsec_policy {
    dh_group         = "DHGroup14" #phase1
    ike_encryption   = "AES256"    #phase2
    ike_integrity    = "SHA256"    #phase2
    ipsec_encryption = "AES256"    #phase1
    ipsec_integrity  = "SHA256"    #phase1
    pfs_group        = "ECP256"    #phase2 DH19
    sa_datasize      = "102400000"
    sa_lifetime      = "27000"

  }

}