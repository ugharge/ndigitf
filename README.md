# Azure HTTP endpoints

Terraform provisions a public Azure Storage static website and an anonymous
Azure Function (`/api/hello`). The Function returns `Hello from Azure Functions!`.
See [TERRAFORM_DESIGN.md](./TERRAFORM_DESIGN.md) for design details.

## Requirements

- Terraform CLI `>= 1.8, < 2.0`
- Azure CLI and an Azure subscription with permission to create resources and
  assign roles
- For Function development/deployment: Python 3.11 and Azure Functions Core
  Tools v4

## Validate

```powershell
terraform -chdir=infra fmt -check -recursive
terraform -chdir=infra init -backend=false
terraform -chdir=infra validate
```

## Deploy

```powershell
az login
az account set --subscription "<subscription-id>"
terraform -chdir=infra init
terraform -chdir=infra plan -out=tfplan
terraform -chdir=infra apply tfplan

$appName = terraform -chdir=infra output -raw function_app_name
Push-Location function
func azure functionapp publish $appName
Pop-Location

terraform -chdir=infra output -raw static_website_url
terraform -chdir=infra output -raw function_endpoint
```

## Remove resources

```powershell
terraform -chdir=infra destroy
```

Review the plan before applying or destroying. Keep Terraform state and plan
files private; state may contain sensitive values. Azure resources may incur
charges until destroyed.
