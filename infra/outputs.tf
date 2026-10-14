output "resource_group_name" {
  description = "Resource group containing the demo resources."
  value       = azurerm_resource_group.main.name
}

output "static_website_url" {
  description = "Public HTTPS URL for the static HTTP service."
  value       = data.azurerm_storage_account.website.primary_web_endpoint
}

output "function_app_name" {
  description = "Function App name for Azure Functions Core Tools deployment."
  value       = azurerm_linux_function_app.api.name
}

output "function_endpoint" {
  description = "Public HTTPS URL for the anonymous HTTP-triggered function."
  value       = "https://${azurerm_linux_function_app.api.default_hostname}/api/hello"
}
