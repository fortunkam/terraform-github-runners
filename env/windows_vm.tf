resource "random_password" "windows_runner_password" {
  keepers = {
    resource_group = azurerm_resource_group.hub.name
  }
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "azurerm_network_interface" "windows_runner" {
  name                = local.windows_runner_internal_nic
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.windows_runner.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "windows_runner" {
  name                = local.windows_runner_name
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  network_interface_ids = [
    azurerm_network_interface.windows_runner.id
  ]
  vm_size = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  storage_os_disk {
    name              = local.windows_runner_disk
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = local.windows_runner_name
    admin_username = local.windows_runner_user_name
    admin_password = random_password.windows_runner_password.result
  }
  os_profile_windows_config {
    provision_vm_agent = true
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "storageblobreader" {
  scope                = azurerm_storage_account.support.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_virtual_machine.windows_runner.identity[0].principal_id
}

resource "azurerm_virtual_machine_extension" "configureWinRunner" {
  name                 = "configureWinRunner"
  virtual_machine_id   = azurerm_virtual_machine.windows_runner.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings           = <<SETTINGS
    {
        "fileUris": [
            "${azurerm_storage_blob.configureWinRunner.url}"
        ]        
    }
SETTINGS
  protected_settings = <<PROTECTED_SETTINGS
    {
        "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File configureWinRunner.ps1 -githubToken ${var.github_runner_token} -githubOrganisationName ${var.github_runner_org}",
        "managedIdentity" : {}
    }
    PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = all
  }
}
