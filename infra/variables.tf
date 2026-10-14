variable "subscription_id" {
  description = "Azure subscription ID. Can also be supplied with ARM_SUBSCRIPTION_ID."
  type        = string
  default     = null
  nullable    = true
}

variable "location" {
  description = "Azure region for the resource group and resources."
  type        = string
  default     = "uksouth"
}

variable "name_prefix" {
  description = "Lowercase alphanumeric prefix used in globally unique resource names."
  type        = string
  default     = "ndigitf"

  validation {
    condition     = can(regex("^[a-z0-9]{3,16}$", var.name_prefix))
    error_message = "name_prefix must contain 3 to 16 lowercase letters or numbers."
  }

}

variable "tags" {
  description = "Tags applied to supported Azure resources."
  type        = map(string)
  default = {
    application = "ndigitf"
    managed_by  = "terraform"
  }
}
