resource "tls_private_key" "linux_runner" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_network_interface" "linux_runner" {
  name                = local.linux_runner_internal_nic
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.linux_runner.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "linux_runner" {
  name                = local.linux_runner_name
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.linux_runner.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.linux_runner.public_key_openssh
  }

  os_disk {
      name              = local.linux_runner_disk
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

    identity {
      type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "linux_runner_storage" {
  scope                = azurerm_storage_account.support.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_linux_virtual_machine.linux_runner.identity[0].principal_id
}

resource "azurerm_virtual_machine_extension" "configureLinuxRunner" {
  name                 = "configureLinuxRunner"
  virtual_machine_id   = azurerm_linux_virtual_machine.linux_runner.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  depends_on = [ azurerm_storage_blob.configureLinuxRunner, azurerm_role_assignment.linux_runner_storage ]

    protected_settings = <<PROTECTED_SETTINGS
    {
        "fileUris": [
            "${azurerm_storage_blob.configureLinuxRunner.url}"
        ],
        "commandToExecute": "bash configureLinuxRunner.sh -t ${var.github_runner_token} -o ${var.github_runner_org}",
        "managedIdentity" : {}
    }
    PROTECTED_SETTINGS

    lifecycle {
        ignore_changes = all
    }
}
