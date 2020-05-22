resource "azurerm_private_dns_zone" "blob" {
  name                = local.storage_blob_dns_zone
  resource_group_name = azurerm_resource_group.spoke.name
  depends_on          = [azurerm_storage_account.storage]
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  name                  = local.storage_dns_link_hub
  resource_group_name   = azurerm_resource_group.spoke.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.hub.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke" {
  name                  = local.storage_dns_link_spoke
  resource_group_name   = azurerm_resource_group.spoke.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
}

resource "azurerm_private_dns_a_record" "a_record" {
  name                = azurerm_storage_account.storage.name
  zone_name           = azurerm_private_dns_zone.blob.name
  resource_group_name = azurerm_resource_group.spoke.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.blob.private_service_connection[0].private_ip_address]
}