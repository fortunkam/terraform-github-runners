resource "random_id" "storage_name" {
  keepers = {
    resource_group = azurerm_resource_group.spoke.name
  }
  byte_length = 8
}

resource "random_id" "deploy_storage_name" {
  keepers = {
    resource_group = azurerm_resource_group.hub.name
  }
  byte_length = 8
}

resource "azurerm_storage_account" "storage" {
  name                     = "sta${lower(random_id.storage_name.hex)}"
  resource_group_name      = azurerm_resource_group.spoke.name
  location                 = azurerm_resource_group.spoke.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  identity {
    type = "SystemAssigned"
  }

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.storage.id]
    # This gets the outbound IP of the user and allows that user to connect to the storage account 
    ip_rules = [lookup(jsondecode(data.http.httpbin.body), "origin")]
    bypass   = ["None"]
  }
}

resource "azurerm_storage_container" "scripts" {
  name                  = local.storage_container_name
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_private_endpoint" "blob" {
  name                = local.storage_private_endpoint
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  subnet_id           = azurerm_subnet.storage.id

  private_service_connection {
    name                           = local.storage_private_link
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
}

resource "azurerm_storage_account" "support" {
  name                     = "sta${lower(random_id.deploy_storage_name.hex)}"
  resource_group_name      = azurerm_resource_group.hub.name
  location                 = azurerm_resource_group.hub.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  identity {
    type = "SystemAssigned"
  }

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.windows_runner.id, azurerm_subnet.linux_runner.id]
    # This gets the outbound IP of the user and allows that user to connect to the storage account 
    ip_rules = [lookup(jsondecode(data.http.httpbin.body), "origin")]
    bypass   = ["None"]
  }
}

resource "azurerm_storage_container" "deploy" {
  name                  = local.deploy_storage_container_name
  storage_account_name  = azurerm_storage_account.support.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "configureWinRunner" {
  name                   = "configureWinRunner.ps1"
  storage_account_name   = azurerm_storage_account.support.name
  storage_container_name = azurerm_storage_container.deploy.name
  type                   = "Block"
  source                 = "${path.module}/scripts/configureWinRunner.ps1"
}

resource "azurerm_storage_blob" "configureLinuxRunner" {
  name                   = "configureLinuxRunner.sh"
  storage_account_name   = azurerm_storage_account.support.name
  storage_container_name = azurerm_storage_container.deploy.name
  type                   = "Block"
  source                 = "${path.module}/scripts/configureLinuxRunner.sh"
}

data "azurerm_storage_account_blob_container_sas" "scripts" {
  connection_string = azurerm_storage_account.support.primary_connection_string
  container_name    = azurerm_storage_container.scripts.name
  https_only        = true

  start  = "${timestamp()}"
  expiry = "${timeadd(timestamp(), "1h")}"

  permissions {
    read   = true
    add    = false
    create = false
    write  = false
    delete = false
    list   = false
  }
}
