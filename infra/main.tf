resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "azurerm_resource_group" "main" {
  name     = "${var.name_prefix}-rg-${random_string.suffix.result}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "website" {
  name                            = "${var.name_prefix}${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  tags                            = var.tags
}

resource "azurerm_storage_account_static_website" "website" {
  storage_account_id = azurerm_storage_account.website.id
  index_document     = "index.html"
}

data "azurerm_storage_account" "website" {
  name                = azurerm_storage_account.website.name
  resource_group_name = azurerm_resource_group.main.name

  depends_on = [azurerm_storage_account_static_website.website]
}

resource "azurerm_storage_blob" "website_index" {
  name                 = "index.html"
  storage_account_name = azurerm_storage_account.website.name
  storage_container_id = "${azurerm_storage_account.website.id}/blobServices/default/containers/$web"
  type                 = "Block"
  source_content       = file("${path.module}/../web/index.html")
  content_type         = "text/html"

  depends_on = [azurerm_storage_account_static_website.website]
}

resource "azurerm_storage_account" "function_host" {
  name                            = "${var.name_prefix}fn${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false
  tags                            = var.tags
}

resource "azurerm_user_assigned_identity" "function_host" {
  name                = "${var.name_prefix}-fn-host-id-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "function_host_blob" {
  scope                            = azurerm_storage_account.function_host.id
  role_definition_name             = "Storage Blob Data Owner"
  principal_id                     = azurerm_user_assigned_identity.function_host.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "function_host_queue" {
  scope                            = azurerm_storage_account.function_host.id
  role_definition_name             = "Storage Queue Data Contributor"
  principal_id                     = azurerm_user_assigned_identity.function_host.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "function_host_table" {
  scope                            = azurerm_storage_account.function_host.id
  role_definition_name             = "Storage Table Data Contributor"
  principal_id                     = azurerm_user_assigned_identity.function_host.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_service_plan" "functions" {
  name                = "${var.name_prefix}-plan-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = var.tags
}

resource "azurerm_linux_function_app" "api" {
  name                = "${var.name_prefix}-api-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.functions.id

  storage_account_name          = azurerm_storage_account.function_host.name
  storage_uses_managed_identity = true
  https_only                    = true
  public_network_access_enabled = true
  functions_extension_version   = "~4"
  builtin_logging_enabled       = true
  tags                          = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.function_host.id]
  }

  site_config {
    application_stack {
      python_version = "3.11"
    }

    ftps_state              = "Disabled"
    minimum_tls_version     = "1.2"
    scm_minimum_tls_version = "1.2"
    http2_enabled           = true
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME         = "python"
    FUNCTIONS_EXTENSION_VERSION      = "~4"
    AzureWebJobsStorage__accountName = azurerm_storage_account.function_host.name
    AzureWebJobsStorage__credential  = "managedidentity"
    AzureWebJobsStorage__clientId    = azurerm_user_assigned_identity.function_host.client_id
  }

  depends_on = [
    azurerm_role_assignment.function_host_blob,
    azurerm_role_assignment.function_host_queue,
    azurerm_role_assignment.function_host_table,
  ]
}
