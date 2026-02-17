data "azurerm_storage_account" "gatling_storage_account" {
  count               = length(var.git.ssh.storage-account-name) > 0 ? 1 : 0
  name                = var.git.ssh.storage-account-name
  resource_group_name = var.resource-group-name
}
