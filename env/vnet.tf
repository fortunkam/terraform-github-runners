resource "azurerm_virtual_network" "hub" {
  name                = local.vnet_hub_name
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = [local.vnet_hub_iprange]
}

resource "azurerm_subnet" "windows_runner" {
  name                 = local.windows_runner_subnet
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.windows_runner_iprange]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_subnet" "linux_runner" {
  name                 = local.linux_runner_subnet
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.linux_runner_iprange]
  service_endpoints    = ["Microsoft.Storage"]
}


resource "azurerm_virtual_network" "spoke" {
  name                = local.vnet_spoke_name
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  address_space       = [local.vnet_spoke_iprange]
}

resource "azurerm_subnet" "storage" {
  name                                           = local.storage_subnet
  resource_group_name                            = azurerm_resource_group.spoke.name
  virtual_network_name                           = azurerm_virtual_network.spoke.name
  address_prefixes                               = [local.storage_subnet_iprange]
  enforce_private_link_endpoint_network_policies = true
  service_endpoints                              = ["Microsoft.Storage"]
}

resource "azurerm_virtual_network_peering" "hubtospoke" {
  name                      = local.hub_to_spoke_vnet_peer
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id
}

resource "azurerm_virtual_network_peering" "spoketohub" {
  name                      = local.spoke_to_hub_vnet_peer
  resource_group_name       = azurerm_resource_group.spoke.name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
}