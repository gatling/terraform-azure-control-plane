# terraform-azure-control-plane

Terraform module to deploy a [Gatling Control Plane](https://docs.gatling.io/reference/install/cloud/private-locations/azure/installation/) on Azure Container Apps.

## Features

- Deploys a Gatling Control Plane as an Azure Container App
- Configures [Private Locations](https://docs.gatling.io/reference/install/cloud/private-locations/azure/configuration/) for load generator provisioning on Azure Virtual Machines
- Optional [Private Packages](https://docs.gatling.io/reference/install/cloud/private-locations/private-packages/) support via Azure Blob Storage
- Optional [Git integration](https://docs.gatling.io/reference/execute/cloud/user/build-from-sources/) for building simulations from sources
- Least-privilege role definitions and role assignments created automatically

## Prerequisites

- Terraform `>= 1.0`
- AzureRM provider
- Existing resource group, virtual network, and subnets
- A Gatling control plane token stored in Azure Key Vault

> [!IMPORTANT]
> This module does **not** create any networking resources (virtual network, subnets, etc.) or the resource group. These must be provided as inputs.

## Examples

- [Complete example](example/)

## Requirements

| Name                                                                  | Version |
|-----------------------------------------------------------------------|---------|
| [terraform](https://www.terraform.io/)                                | >= 1.0  |
| [azurerm](https://registry.terraform.io/providers/hashicorp/azurerm/) | >= 3.0  |

## Providers

| Name                                                                  |
|-----------------------------------------------------------------------|
| [azurerm](https://registry.terraform.io/providers/hashicorp/azurerm/) |

## Resources

| Name                                         | Type     |
|----------------------------------------------|----------|
| `azurerm_container_app_environment`          | resource |
| `azurerm_container_app_environment_storage`  | resource |
| `azurerm_container_app`                      | resource |
| `azurerm_role_definition`                    | resource |
| `azurerm_role_assignment`                    | resource |
| `azurerm_key_vault_access_policy`            | resource |

## Documentation

- [Azure Private Locations — Installation](https://docs.gatling.io/reference/install/cloud/private-locations/azure/installation/)
- [Azure Private Locations — Configuration](https://docs.gatling.io/reference/install/cloud/private-locations/azure/configuration/)
- [Private Packages](https://docs.gatling.io/reference/install/cloud/private-locations/private-packages/)
- [Build from Sources](https://docs.gatling.io/reference/execute/cloud/user/build-from-sources/)

## License

Apache 2.0 — see [LICENSE](LICENSE) for details.
