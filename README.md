# Azure Hub-and-Spoke Terraform Template

A production-ready Terraform template that deploys a fully private, multi-environment Azure hub-and-spoke architecture. Every service is secured with private endpoints or VNet injection — no public IPs on workloads.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Subscription Model](#2-subscription-model)
3. [IP Address Layout](#3-ip-address-layout)
4. [Directory Structure](#4-directory-structure)
5. [Naming Convention](#5-naming-convention)
6. [Prerequisites](#6-prerequisites)
7. [Step-by-Step Deployment](#7-step-by-step-deployment)
8. [Hub Module Reference](#8-hub-module-reference)
9. [Spoke Module Reference](#9-spoke-module-reference)
10. [Hub Variable Reference](#10-hub-variable-reference)
11. [Spoke Variable Reference](#11-spoke-variable-reference)
12. [Networking Patterns](#12-networking-patterns)
13. [Feature Flags](#13-feature-flags)
14. [Environment Customization Guide](#14-environment-customization-guide)
15. [Secrets and Sensitive Values](#15-secrets-and-sensitive-values)
16. [CI/CD Pipeline Integration](#16-cicd-pipeline-integration)
17. [Common Operations](#17-common-operations)
18. [Troubleshooting](#18-troubleshooting)

---

## 1. Architecture Overview

```
Internet
    │
    ▼
Application Gateway (WAF_v2)          ← Entry point for inbound HTTPS traffic
    │                                     Only component with a public IP
    ▼
API Management (Internal VNet mode)   ← API gateway, policy enforcement
    │
    ▼
┌──────────────────── Hub VNet ───────────────────────┐
│  AzureFirewallSubnet   ← All spoke egress routes here │
│  AzureBastionSubnet    ← Secure VM access (no PIP)    │
│  GatewaySubnet         ← Optional VPN gateway          │
│  snet-appgw            ← Application Gateway           │
│  snet-apim             ← API Management (Internal)     │
│  snet-mgmt             ← Jumpbox VM + Agent VM + KV PE │
└─────────────────────────────────────────────────────┘
    │                │
    VNet Peering     VNet Peering
    │                │
    ▼                ▼
Spoke VNet          Another Spoke VNet (staging, prod, etc.)
    │
    ├── snet-app          App Service VNet integration (outbound)
    ├── snet-func         Function App VNet integration (outbound)
    ├── snet-pe           Private endpoints (all inbound service traffic)
    ├── snet-dbkpub       Databricks public subnet
    ├── snet-dbkprv       Databricks private subnet
    ├── snet-sqlmi        SQL Managed Instance (delegated)
    ├── snet-mysql        MySQL Flexible (delegated)
    ├── snet-psql         PostgreSQL Flexible (delegated)
    ├── snet-aci          Container Instance (delegated)
    └── snet-aif          AI Foundry compute clusters
```

**Key design principles:**

- **Zero public exposure on workloads** — App Services, databases, caches, AI services all use private endpoints. No public IP except Application Gateway.
- **Egress through firewall** — A User Defined Route (UDR) on every spoke subnet sends `0.0.0.0/0` to the hub firewall private IP.
- **Per-environment isolation** — Each environment (dev, staging, prod) has its own hub AND spoke subscription. Compromising dev cannot touch prod.
- **Managed identity everywhere** — Services authenticate to each other using SystemAssigned managed identities, not connection strings in config.

---

## 2. Subscription Model

This template uses **6 Azure subscriptions** — one hub and one spoke per environment:

| Subscription | Role | CIDR | Example resources |
|---|---|---|---|
| hub-dev | Dev hub | `10.10.0.0/16` | `azfw-qoc-hub-we-dev-001`, `kv-qoc-hub-we-dev-001` |
| hub-staging | Staging hub | `10.20.0.0/16` | `azfw-qoc-hub-we-staging-001` |
| hub-prod | Prod hub | `10.30.0.0/16` | `azfw-qoc-hub-we-prod-001` |
| dev | Dev workloads | `10.11.0.0/16` | `app-fe-qoc-we-dev-001`, `sql-web-qoc-we-dev-001` |
| staging | Staging workloads | `10.21.0.0/16` | `app-fe-qoc-we-staging-001` |
| prod | Prod workloads | `10.31.0.0/16` | `app-fe-qoc-we-prod-001` |

**Why per-environment hubs?** If dev and prod share a hub, a misconfiguration in dev's firewall rules could affect prod traffic. Separate hubs give complete network-level isolation between environments.

**Why two separate subscriptions per environment (hub + spoke)?** Azure subscription limits apply per subscription (VMs, IPs, etc.). Separate subscriptions also give clean cost isolation — hub costs are hub costs, workload costs are workload costs.

---

## 3. IP Address Layout

### Hub subnets (each hub follows the same pattern with its own /16)

| Subnet | CIDR offset | Name (Azure-required or custom) | Used by |
|---|---|---|---|
| Firewall | `x.x.0.0/26` | `AzureFirewallSubnet` | Azure Firewall (name cannot change) |
| Gateway | `x.x.1.0/27` | `GatewaySubnet` | VPN Gateway (name cannot change) |
| Bastion | `x.x.2.0/26` | `AzureBastionSubnet` | Azure Bastion (name cannot change) |
| App Gateway | `x.x.3.0/24` | `snet-appgw-*` | Application Gateway + WAF |
| APIM | `x.x.4.0/28` | `snet-apim-*` | API Management (minimum /28) |
| Management | `x.x.5.0/24` | `snet-mgmt-*` | Jumpbox VM, Agent VM, Key Vault PE |

### Spoke subnets

| Subnet | CIDR offset | Purpose |
|---|---|---|
| `snet-app-*` | `x.x.0.0/24` | App Service outbound VNet integration |
| `snet-func-*` | `x.x.1.0/24` | Function App outbound VNet integration |
| `snet-pe-*` | `x.x.2.0/24` | All private endpoints (PE network policies disabled) |
| `snet-dbkpub-*` | `x.x.3.0/24` | Databricks public subnet |
| `snet-dbkprv-*` | `x.x.4.0/24` | Databricks private subnet |
| `snet-sqlmi-*` | `x.x.5.0/24` | SQL Managed Instance (delegated) |
| `snet-mysql-*` | `x.x.6.0/24` | MySQL Flexible Server (delegated) |
| `snet-psql-*` | `x.x.7.0/24` | PostgreSQL Flexible Server (delegated) |
| `snet-aci-*` | `x.x.8.0/24` | Azure Container Instances (delegated) |
| `snet-aif-*` | `x.x.9.0/24` | AI Foundry compute clusters |

### Full CIDR table

| Environment | Hub VNet | Spoke VNet |
|---|---|---|
| dev | `10.10.0.0/16` | `10.11.0.0/16` |
| staging | `10.20.0.0/16` | `10.21.0.0/16` |
| prod | `10.30.0.0/16` | `10.31.0.0/16` |

---

## 4. Directory Structure

```
terraform/
│
├── hub/                        ← Hub Terraform root (run against hub subscriptions)
│   ├── main.tf                 ← Calls all hub modules: firewall, AppGW, APIM, KV, ACR, VMs
│   ├── locals.tf               ← Derives hub_suffix, hub_rg_name, pdns_rg_name, common_tags
│   ├── providers.tf            ← azurerm provider, Terraform version constraint (>= 1.5.0)
│   ├── outputs.tf              ← Exports: hub_vnet_id, hub_vnet_name, hub_rg_name,
│   │                                       firewall_private_ip, key_vault_id
│   └── variables.tf            ← All hub input variables (subscription_id, org, CIDRs, flags)
│
├── spoke/                      ← Spoke Terraform root (run against dev/staging/prod subscriptions)
│   ├── main.tf                 ← Calls all spoke modules: networking, workloads, DNS zones
│   ├── locals.tf               ← Derives spoke_suffix, RG names, storage_name, dns_vnet_links
│   ├── providers.tf            ← Two providers: default (spoke) + azurerm.hub alias (cross-sub peering)
│   ├── outputs.tf              ← Exports spoke VNet ID, monitoring IDs, storage keys
│   └── variables.tf            ← All spoke input variables (hub references, feature flags, SKUs)
│
├── modules/                    ← Reusable modules — do NOT edit per deployment
│   ├── agent_vm/               ← Linux CI/CD agent VM (hub only)
│   ├── ai_foundry/             ← Azure Machine Learning workspace + compute cluster
│   ├── ai_vision/              ← Azure AI Vision (Computer Vision) + private endpoint
│   ├── apim/                   ← API Management with optional Internal VNet integration
│   ├── app_service/            ← App Service Plan + multiple Linux web apps
│   ├── application_gateway/    ← Application Gateway WAF_v2 + WAF policy
│   ├── bastion/                ← Azure Bastion (Standard or Basic SKU)
│   ├── bing_search/            ← Bing Search v7 + Custom Search (public endpoint only)
│   ├── container_instance/     ← Azure Container Instances (VNet-injected)
│   ├── container_registry/     ← Azure Container Registry + private endpoint
│   ├── cosmosdb_mongo/         ← CosmosDB MongoDB API + private endpoint
│   ├── cosmosdb_nosql/         ← CosmosDB NoSQL (SQL API) + private endpoint
│   ├── databricks/             ← Azure Databricks workspace (VNet-injected, no public IP)
│   ├── event_grid/             ← Event Grid domain + private endpoint
│   ├── firewall/               ← Azure Firewall + policy + rule collection group
│   ├── front_door/             ← Azure Front Door (CDN profile, endpoint, origin, WAF route)
│   ├── function_app/           ← Function App Plan + multiple Linux function apps
│   ├── jumpbox_vm/             ← Windows jumpbox VM (hub only)
│   ├── key_vault/              ← Key Vault + access policies + private endpoint
│   ├── monitoring/             ← Log Analytics Workspace + Application Insights
│   ├── mysql_flexible/         ← MySQL Flexible Server (VNet-injected, not PE)
│   ├── network_security_group/ ← NSG with configurable security rules
│   ├── openai/                 ← Azure OpenAI + model deployments + private endpoint
│   ├── postgresql_flexible/    ← PostgreSQL Flexible Server (VNet-injected, not PE)
│   ├── private_dns_zone/       ← Private DNS zone + VNet links
│   ├── redis_cache/            ← Azure Cache for Redis + private endpoint
│   ├── resource_group/         ← Simple resource group wrapper
│   ├── route_table/            ← UDR route table (used for force-tunneling through firewall)
│   ├── search_service/         ← Azure AI Search + private endpoint
│   ├── service_bus/            ← Service Bus namespace + queues + topics + private endpoint
│   ├── speech_service/         ← Azure AI Speech + private endpoint
│   ├── sql_database/           ← Azure SQL Server + multiple databases + private endpoint
│   ├── sql_managed_instance/   ← SQL Managed Instance + its own NSG + UDR (self-contained)
│   ├── storage_account/        ← Storage account + blob PE + file PE
│   ├── subnet/                 ← Subnet + optional NSG association + optional UDR association
│   ├── virtual_network/        ← Virtual network wrapper
│   └── vpn_gateway/            ← VPN Gateway (hub only)
│
└── subscriptions/              ← Per-environment config files — THIS is where you work
    ├── hub-dev/
    │   ├── values.tfvars       ← Hub-dev input values (subscription ID, CIDRs, flags)
    │   └── backend.tfvars      ← Where to store Terraform state for hub-dev
    ├── hub-staging/
    │   ├── values.tfvars
    │   └── backend.tfvars
    ├── hub-prod/
    │   ├── values.tfvars
    │   └── backend.tfvars
    ├── dev/
    │   ├── values.tfvars       ← Dev spoke input values (hub references, feature flags, SKUs)
    │   └── backend.tfvars
    ├── staging/
    │   ├── values.tfvars
    │   └── backend.tfvars
    └── prod/
        ├── values.tfvars
        └── backend.tfvars
```

**The rule:** You only ever edit files in `subscriptions/`. The `hub/`, `spoke/`, and `modules/` directories are the engine — they are shared across all deployments.

---

## 5. Naming Convention

Every resource follows a consistent pattern:

```
{resource-type}-{qualifier}-{org}-{region}-{environment}-{instance}
```

### Hub resources

Pattern: `{type}-{org}-hub-{region}-{environment}-{instance}`

| Resource | Example name |
|---|---|
| Resource group | `rg-qoc-hub-we-prod-001` |
| VNet | `vnet-qoc-hub-we-prod-001` |
| Firewall | `azfw-qoc-hub-we-prod-001` |
| App Gateway | `agw-qoc-hub-we-prod-001` |
| Bastion | `bas-qoc-hub-we-prod-001` |
| APIM | `apim-qoc-hub-we-prod-001` |
| Key Vault | `kv-qoc-hub-we-prod-001` |
| Container Registry | `acr-qoc-hub-we-prod-001` |
| Jumpbox VM | `vm-jmp-qoc-hub-we-prod-001` |
| Agent VM | `vm-agt-qoc-hub-we-prod-001` |

### Spoke resources

Pattern: `{type}-{project}-{org}-{region}-{environment}-{instance}`

| Resource | Example name |
|---|---|
| Resource group | `rg-web-qoc-we-prod-001` |
| VNet | `vnet-qoc-we-prod-001` |
| App Service | `app-fe-qoc-we-prod-001` (one per name in `app_service_names`) |
| Function App | `func-proc-qoc-we-prod-001` (one per name in `function_app_names`) |
| SQL Server | `sql-web-qoc-we-prod-001` |
| Redis | `redis-web-qoc-we-prod-001` |
| Service Bus | `sb-web-qoc-we-prod-001` |
| Storage Account | `stqocwebweprod001` (no dashes, max 24 chars) |
| OpenAI | `oai-web-qoc-we-prod-001` |
| AI Search | `srch-web-qoc-we-prod-001` |

### Changing names for a new client or project

Only edit these four fields in `values.tfvars` and all names rebuild automatically:
- `org` — your client/organization code (e.g., `abc`)
- `project` — workload name (e.g., `api`, `data`, `mobile`)
- `region_short` — matches `location` (e.g., `eus` for `eastus`)
- `instance` — instance number (e.g., `002` for a second deployment in the same region)

---

## 6. Prerequisites

### Tools required

| Tool | Minimum version | Install |
|---|---|---|
| Terraform | 1.5.0 | https://developer.hashicorp.com/terraform/downloads |
| Azure CLI | 2.50.0 | https://learn.microsoft.com/en-us/cli/azure/install-azure-cli |

### Azure subscriptions

You need **6 Azure subscriptions** (or fewer if you share a hub):
- `hub-dev` — hub subscription for the dev environment
- `hub-staging` — hub subscription for the staging environment
- `hub-prod` — hub subscription for the prod environment
- `dev` — dev workloads spoke
- `staging` — staging workloads spoke
- `prod` — prod workloads spoke

### Azure permissions

The identity running Terraform (service principal or your `az login` user) needs:
- **Contributor** on each target subscription (to create all resources)
- **User Access Administrator** on each target subscription (to create role assignments for managed identities)

### Pre-create Terraform state backends

Before running `terraform init` for any root, create the Azure storage backend manually:

```bash
# Example for hub-dev — repeat for all 6 environments
az group create --name rg-tfstate-qoc-hub-we-dev-001 --location westeurope --subscription <hub-dev-subscription-id>
az storage account create \
  --name stqochubwedevtfstate001 \
  --resource-group rg-tfstate-qoc-hub-we-dev-001 \
  --subscription <hub-dev-subscription-id> \
  --location westeurope \
  --sku Standard_LRS \
  --allow-blob-public-access false
az storage container create \
  --name tfstate \
  --account-name stqochubwedevtfstate001 \
  --subscription <hub-dev-subscription-id>
```

Then update each `backend.tfvars` file to match:

```hcl
# subscriptions/hub-dev/backend.tfvars
resource_group_name  = "rg-tfstate-qoc-hub-we-dev-001"
storage_account_name = "stqochubwedevtfstate001"
container_name       = "tfstate"
key                  = "hub-dev/terraform.tfstate"
```

---

## 7. Step-by-Step Deployment

Deploy in this order — **hub always before spoke**. Both use the same `hub/` Terraform root, just with different `values.tfvars` and `backend.tfvars`.

### Step 1 — Fill in subscription IDs

Open each `subscriptions/*/values.tfvars` and replace the placeholder subscription IDs:

```hcl
# subscriptions/hub-dev/values.tfvars
subscription_id = "your-actual-hub-dev-subscription-id"

# subscriptions/hub-staging/values.tfvars
subscription_id = "your-actual-hub-staging-subscription-id"

# subscriptions/hub-prod/values.tfvars
subscription_id = "your-actual-hub-prod-subscription-id"

# subscriptions/dev/values.tfvars
subscription_id     = "your-actual-dev-subscription-id"
hub_subscription_id = "your-actual-hub-dev-subscription-id"

# subscriptions/staging/values.tfvars
subscription_id     = "your-actual-staging-subscription-id"
hub_subscription_id = "your-actual-hub-staging-subscription-id"

# subscriptions/prod/values.tfvars
subscription_id     = "your-actual-prod-subscription-id"
hub_subscription_id = "your-actual-hub-prod-subscription-id"
```

### Step 2 — Deploy hub-dev

```bash
az login
az account set --subscription <hub-dev-subscription-id>

cd hub/
terraform init -backend-config="../subscriptions/hub-dev/backend.tfvars"
terraform plan  -var-file="../subscriptions/hub-dev/values.tfvars" \
                -var="vm_admin_password=YourSecureP@ssword1"
terraform apply -var-file="../subscriptions/hub-dev/values.tfvars" \
                -var="vm_admin_password=YourSecureP@ssword1"
```

After apply, run `terraform output` and copy the values:

```bash
terraform output
# hub_vnet_id         = "/subscriptions/.../vnet-qoc-hub-we-dev-001"
# hub_vnet_name       = "vnet-qoc-hub-we-dev-001"
# hub_rg_name         = "rg-qoc-hub-we-dev-001"
# firewall_private_ip = "10.10.0.4"
# key_vault_id        = "/subscriptions/.../kv-qoc-hub-we-dev-001"
```

### Step 3 — Fill in dev spoke hub references

Open `subscriptions/dev/values.tfvars` and fill in the values from Step 2:

```hcl
hub_subscription_id     = "your-hub-dev-subscription-id"
hub_vnet_id             = "/subscriptions/.../vnet-qoc-hub-we-dev-001"
hub_vnet_name           = "vnet-qoc-hub-we-dev-001"
hub_rg_name             = "rg-qoc-hub-we-dev-001"
hub_firewall_private_ip = "10.10.0.4"
hub_keyvault_id         = "/subscriptions/.../kv-qoc-hub-we-dev-001"
```

### Step 4 — Deploy dev spoke

```bash
az account set --subscription <dev-subscription-id>

# IMPORTANT: you must run init again when switching environments
# because each environment has a different backend
terraform init -reconfigure -backend-config="../subscriptions/dev/backend.tfvars"

terraform plan  -var-file="../subscriptions/dev/values.tfvars" \
                -var="sql_admin_password=YourSecureP@ssword1" \
                -var="mysql_admin_password=YourSecureP@ssword1" \
                -var="postgresql_admin_password=YourSecureP@ssword1"

terraform apply -var-file="../subscriptions/dev/values.tfvars" \
                -var="sql_admin_password=YourSecureP@ssword1" \
                -var="mysql_admin_password=YourSecureP@ssword1" \
                -var="postgresql_admin_password=YourSecureP@ssword1"
```

### Step 5 — Repeat for staging and prod

Repeat Steps 2–4 using `hub-staging`/`staging` and `hub-prod`/`prod` configs.

**For prod, you must pass the `-reconfigure` flag when switching from a previous environment's `terraform init`:**

```bash
az account set --subscription <hub-prod-subscription-id>
cd hub/
terraform init -reconfigure -backend-config="../subscriptions/hub-prod/backend.tfvars"
terraform apply -var-file="../subscriptions/hub-prod/values.tfvars" -var="vm_admin_password=..."

# Then spoke:
az account set --subscription <prod-subscription-id>
cd spoke/
terraform init -reconfigure -backend-config="../subscriptions/prod/backend.tfvars"
terraform apply -var-file="../subscriptions/prod/values.tfvars" \
                -var="sql_admin_password=..." \
                -var="mysql_admin_password=..." \
                -var="postgresql_admin_password=..."
```

### Destroy an environment

```bash
cd spoke/
terraform init -reconfigure -backend-config="../subscriptions/dev/backend.tfvars"
terraform destroy -var-file="../subscriptions/dev/values.tfvars" ...

# Then destroy the hub (spoke must go first — peering depends on hub VNet)
cd hub/
terraform init -reconfigure -backend-config="../subscriptions/hub-dev/backend.tfvars"
terraform destroy -var-file="../subscriptions/hub-dev/values.tfvars" ...
```

---

## 8. Hub Module Reference

These modules are called from `hub/main.tf`. All are conditionally enabled via feature flags.

### `modules/firewall`

Deploys Azure Firewall with a policy and rule collection group.

| Resource created | Description |
|---|---|
| `azurerm_public_ip` | Static Standard public IP for the firewall |
| `azurerm_firewall_policy` | Policy with DNS proxy enabled and configurable threat intel mode |
| `azurerm_firewall` | AZFW_VNet SKU, attached to `AzureFirewallSubnet` |
| `azurerm_firewall_policy_rule_collection_group` | Network and application rule collections |

**Key behaviour:** DNS proxy is always enabled on the policy — this is required for spoke workloads to resolve Azure private DNS zones correctly when traffic is forced through the firewall.

**Variables:**
- `sku_tier` — `Standard` or `Premium`. Premium adds IDPS and TLS inspection.
- `network_rules` — List of network rule collection objects. Defaults to empty.
- `application_rules` — List of application rule collection objects. Defaults to empty.

### `modules/application_gateway`

Deploys Application Gateway WAF_v2 with an attached WAF policy.

| Resource created | Description |
|---|---|
| `azurerm_public_ip` | Static Standard public IP |
| `azurerm_web_application_firewall_policy` | WAF policy with managed rule set |
| `azurerm_application_gateway` | WAF_v2 SKU, attached to `snet-appgw` |

**Key behaviour:** Ships with one default HTTPS listener and an HTTP→HTTPS redirect. Additional backend pools can be added via `app_gateway_backend_pools`. The WAF policy handles all WAF configuration.

### `modules/bastion`

Deploys Azure Bastion for secure SSH/RDP access to hub VMs without public IPs.

**Variables:**
- `sku` — `Basic` (no native client, no file copy) or `Standard` (native client support, file copy). Defaults to `Standard`.

### `modules/apim`

Deploys API Management. When `subnet_id` is provided, APIM is placed in Internal VNet mode (no public access).

**Key behaviour:** VNet integration uses a dynamic block — if `subnet_id` is empty, APIM is deployed without VNet. Hub always passes `subnet_id = module.snet_apim.id` and `virtual_network_type = "Internal"`, so APIM is always fully internal.

The APIM subnet requires a dedicated NSG with port 3443 open from `ApiManagement` service tag. The hub creates this NSG (`nsg_apim`) with all required rules pre-configured.

### `modules/key_vault`

Deploys Key Vault with access policies, network ACLs, and a private endpoint.

| Resource created | Description |
|---|---|
| `azurerm_key_vault` | Private, RBAC disabled (access policies used) |
| `azurerm_key_vault_access_policy.terraform` | Full access for the deploying identity |
| `azurerm_key_vault_access_policy.custom` | For each entry in `access_policies` map |
| `azurerm_private_endpoint` | PE in the management subnet |

**Key behaviour:** The hub Key Vault holds platform-level secrets (TLS certificates, pipeline credentials). Spoke services get read-only access granted separately via the `app_service` module's `azurerm_key_vault_access_policy`.

### `modules/container_registry`

Deploys Azure Container Registry with a private endpoint in the management subnet. All spoke environments share the hub's ACR — they pull images over the private endpoint, never over the internet.

### `modules/jumpbox_vm` and `modules/agent_vm`

- **jumpbox_vm** — Windows VM for manual Azure Portal-equivalent access from inside the network.
- **agent_vm** — Linux VM configured as a self-hosted CI/CD agent (Azure DevOps, GitHub Actions). Uses SSH key authentication (`vm_ssh_public_key`).

Both VMs sit in `snet-mgmt` and are accessible only via Bastion.

### `modules/vpn_gateway`

Deploys a VPN Gateway in `GatewaySubnet`. Disabled by default (`enable_vpn_gateway = false`). Use when you need site-to-site connectivity from an on-premises network.

---

## 9. Spoke Module Reference

These modules are called from `spoke/main.tf`. All workload modules are conditionally enabled with feature flags.

### Monitoring (always deployed)

**`modules/monitoring`**

| Resource created | Description |
|---|---|
| `azurerm_log_analytics_workspace` | Central log sink (`{name}-law`) |
| `azurerm_application_insights` | App performance monitoring, linked to the workspace (`{name}-appi`) |

Deployed first — all other modules receive the Application Insights connection string from monitoring outputs.

### App Service (`enable_app_service`)

**`modules/app_service`**

| Resource created | Description |
|---|---|
| `azurerm_service_plan` | Linux App Service Plan |
| `azurerm_linux_web_app` | One per name in `app_service_names` |
| `azurerm_private_endpoint` | One per web app, in `snet-pe` |
| `azurerm_key_vault_access_policy` | Read-only secret access for each app's managed identity |

**Networking:** Outbound traffic goes through `snet-app` (VNet integration with `vnet_route_all_enabled = true` so ALL traffic goes through the firewall). Inbound traffic comes through the private endpoint in `snet-pe`.

**App names:** Each name in `app_service_names` creates one web app named `app-{name}-{org}-{region}-{env}-{instance}`. Default: `["fe", "be"]` → `app-fe-...`, `app-be-...`.

**Application stack:** Node.js 20 LTS by default. Change `application_stack` in `modules/app_service/main.tf` to use Python, .NET, Java, etc.

### Function App (`enable_function_app`)

**`modules/function_app`**

Same pattern as App Service — one function app per name in `function_app_names`. Uses the Elastic Premium plan by default (EP1 in dev, EP2 in prod) which supports VNet integration and scaling to zero.

**Dependency:** Requires `enable_storage = true` because the function app uses the spoke storage account for its internal state.

### Storage Account (`enable_storage`)

**`modules/storage_account`**

| Resource created | Description |
|---|---|
| `azurerm_storage_account` | StorageV2, all public access denied |
| `azurerm_private_endpoint` (blob) | In `snet-pe` |
| `azurerm_private_endpoint` (file) | In `snet-pe` |

Name format: `st{org}{project}{region}{env}{instance}` (no dashes, lowercase, max 24 chars). Example: `stqocwebweprod001`.

### Redis Cache (`enable_redis`)

**`modules/redis_cache`**

Private endpoint in `snet-pe`. `maxmemory_policy = "allkeys-lru"` by default. Non-SSL port is disabled (Azure default). SSL only via port 6380.

- Dev/staging: `Standard C1` SKU
- Prod: `Premium P1` SKU (supports VNet injection, clustering, geo-replication)

### SQL Database (`enable_sql_db`)

**`modules/sql_database`**

| Resource created | Description |
|---|---|
| `azurerm_mssql_server` | SQL Server 12.0, public access disabled |
| `azurerm_mssql_database` | One per entry in `sql_databases` map |
| `azurerm_private_endpoint` | In `snet-pe` |

Each database gets a short-term backup retention of 7 days with 12-hour backup interval. Databases are defined as a map:

```hcl
sql_databases = {
  main  = { sku_name = "S2", max_size_gb = 64 }
  audit = { sku_name = "S1", max_size_gb = 32 }
}
```

### SQL Managed Instance (`enable_sql_mi`)

**`modules/sql_managed_instance`**

Self-contained module that creates its own NSG and UDR on the SQL MI subnet (required by Azure). VNet-injected into `snet-sqlmi` (delegated to `Microsoft.Sql/managedInstances`).

**Warning:** SQL MI takes 4–6 hours to provision and costs significantly more than SQL Database. Disabled by default.

### Service Bus (`enable_service_bus`)

**`modules/service_bus`**

Namespace + optional queues + optional topics + private endpoint. Must use Premium SKU for private endpoints (`service_bus_sku = "Premium"`).

```hcl
service_bus_queues  = ["orders", "notifications"]
service_bus_topics  = ["events"]
```

### Event Grid (`enable_event_grid`)

**`modules/event_grid`**

Event Grid domain with private endpoint. After deployment, create topics within the domain to publish events. The domain endpoint is only reachable from within the VNet.

### Azure OpenAI (`enable_openai`)

**`modules/openai`**

| Resource created | Description |
|---|---|
| `azurerm_cognitive_account` | OpenAI kind, public access disabled, custom subdomain set |
| `azurerm_cognitive_deployment` | One per entry in `openai_deployments` map |
| `azurerm_private_endpoint` | Subresource: `account` |

Model deployments use the `sku {}` block (not `scale {}` — that was the old schema). Example configuration:

```hcl
openai_deployments = {
  gpt4o = {
    model_name    = "gpt-4o"
    model_version = "2024-11-20"
    sku_name      = "GlobalStandard"   # Standard | GlobalStandard | DataZoneStandard
    capacity      = 10                  # TPM in thousands
  }
}
```

**Note:** OpenAI requires Microsoft approval for your subscription before you can deploy models. The `openai_location` variable defaults to `eastus` because OpenAI capacity varies significantly by region.

**DNS zone:** `privatelink.openai.azure.com` (separate from the cognitive services zone used by Speech/Vision).

### AI Search (`enable_search`)

**`modules/search_service`**

Azure AI Search with private endpoint. The private endpoint subresource is `searchService`. DNS zone: `privatelink.search.windows.net`.

**Note:** The `Basic` SKU does not support private endpoints. Use `standard` or higher when `enable_search = true`.

### Azure AI Speech (`enable_speech`)

**`modules/speech_service`**

Cognitive Services account (kind: `SpeechServices`) with custom subdomain and private endpoint. DNS zone: `privatelink.cognitiveservices.azure.com`.

### Azure AI Vision (`enable_ai_vision`)

**`modules/ai_vision`**

Cognitive Services account (kind: `ComputerVision`) with custom subdomain and private endpoint. Shares the `privatelink.cognitiveservices.azure.com` DNS zone with Speech.

### MySQL Flexible Server (`enable_mysql_flexible`)

**`modules/mysql_flexible`**

VNet-injected into `snet-mysql` (not a private endpoint — the server itself lives in the subnet). Private DNS zone `privatelink.mysql.database.azure.com` is linked to the VNet for name resolution.

```hcl
mysql_admin_login    = "mysqladmin"
mysql_admin_password = "..."   # pass via -var flag
mysql_sku_name       = "Standard_D4ds_v4"
mysql_version        = "8.0.21"
mysql_storage_gb     = 128
```

### PostgreSQL Flexible Server (`enable_postgresql`)

**`modules/postgresql_flexible`**

Same VNet injection pattern as MySQL. Supports high availability modes (`SameZone` or `ZoneRedundant`) via the `high_availability_mode` variable (defaults to `Disabled`).

```hcl
postgresql_admin_login    = "psqladmin"
postgresql_admin_password = "..."   # pass via -var flag
postgresql_sku_name       = "Standard_D4s_v3"
postgresql_version        = "14"
postgresql_storage_mb     = 131072   # 128 GB
```

### CosmosDB NoSQL (`enable_cosmosdb_nosql`)

**`modules/cosmosdb_nosql`**

CosmosDB account (GlobalDocumentDB kind) + SQL databases + containers + private endpoint.

```hcl
# Default — deploys empty account. Customize in spoke/main.tf or add a variable:
databases = {
  appdb = {
    throughput = 400
    containers = {
      users = {
        partition_key_path = "/userId"
        throughput         = 400
      }
    }
  }
}
```

DNS zone: `privatelink.documents.azure.com`

### CosmosDB MongoDB (`enable_cosmosdb_mongo`)

**`modules/cosmosdb_mongo`**

CosmosDB account (MongoDB kind) + databases + collections + private endpoint.

DNS zone: `privatelink.mongo.cosmos.azure.com` — **different from the NoSQL zone**. Both can coexist.

### Databricks (`enable_databricks`)

**`modules/databricks`**

Azure Databricks workspace with VNet injection (no public IP mode). Uses two dedicated subnets with Databricks delegation:
- `snet-dbkpub` — Databricks public subnet
- `snet-dbkprv` — Databricks private subnet

Both subnets have NSGs created by the spoke (managed by the spoke NSG modules). The module receives the **subnet IDs** (which are also the NSG association resource IDs in azurerm) — not the NSG resource IDs directly.

Disabled by default — Databricks is expensive.

### AI Foundry (`enable_ai_foundry`)

**`modules/ai_foundry`**

Azure Machine Learning workspace (which backs AI Foundry) with:
- A CPU compute cluster in `snet-aif`
- A private endpoint for the workspace API in `snet-pe`
- Two DNS zones: `privatelink.api.azureml.ms` + `privatelink.notebooks.azure.net`

**Dependencies:** Requires `enable_storage = true` (storage account is mandatory for AML workspace).

```hcl
enable_ai_foundry = true   # also set enable_storage = true
```

### Container Instance (`enable_container_instance`)

**`modules/container_instance`**

VNet-injected into `snet-aci`. Containers are defined via the `container_instance_containers` variable:

```hcl
container_instance_containers = [
  {
    name   = "myapp"
    image  = "myacr.azurecr.io/myapp:latest"
    cpu    = 1
    memory = 1.5
    ports  = [{ port = 8080, protocol = "TCP" }]
    environment_variables = {
      ENVIRONMENT = "dev"
    }
  }
]
```

### Bing Search (`enable_bing_search`)

**`modules/bing_search`**

Creates Bing Search v7 and Bing Custom Search accounts. These are **internet-facing** — private endpoints are not supported for Bing Search. Access via HTTPS from your application code using the API key stored in Key Vault. Disabled by default.

---

## 10. Hub Variable Reference

All variables are in `hub/variables.tf`. Set values in `subscriptions/hub-*/values.tfvars`.

### Identity

| Variable | Type | Default | Description |
|---|---|---|---|
| `subscription_id` | string | — | Hub Azure subscription ID. **Required.** |

### Naming

| Variable | Type | Default | Description |
|---|---|---|---|
| `org` | string | — | Short org/project code. Used in every resource name. e.g., `qoc` |
| `environment` | string | `shared` | Environment this hub serves: `dev`, `staging`, `prod`, or `shared` |
| `location` | string | `westeurope` | Azure region for all hub resources |
| `region_short` | string | `we` | 2–3 char region code matching `location`. e.g., `we`, `eus`, `use` |
| `instance` | string | `001` | 3-digit instance suffix. Increment for second deployments in same region |
| `tags` | map(string) | `{}` | Additional tags applied to all resources |

### Networking

| Variable | Type | Default | Description |
|---|---|---|---|
| `hub_vnet_cidr` | string | `10.0.0.0/16` | Hub VNet address space. Must not overlap with spoke or other hubs. |
| `hub_subnet_cidrs.firewall` | string | `10.0.0.0/26` | Minimum `/26` required by Azure Firewall |
| `hub_subnet_cidrs.gateway` | string | `10.0.1.0/27` | Minimum `/27` required by VPN Gateway |
| `hub_subnet_cidrs.bastion` | string | `10.0.2.0/26` | Minimum `/26` required by Azure Bastion |
| `hub_subnet_cidrs.app_gateway` | string | `10.0.3.0/24` | Application Gateway subnet |
| `hub_subnet_cidrs.apim` | string | `10.0.4.0/28` | Minimum `/28` required by APIM |
| `hub_subnet_cidrs.management` | string | `10.0.5.0/24` | VMs, Key Vault PE, ACR PE |

### Feature Flags

| Variable | Default | Description |
|---|---|---|
| `enable_firewall` | `true` | Azure Firewall. Turn off to save cost in non-prod (UDR routes will fail without it) |
| `enable_app_gateway` | `true` | Application Gateway with WAF_v2 |
| `enable_vpn_gateway` | `false` | VPN Gateway for site-to-site connectivity |
| `enable_bastion` | `true` | Azure Bastion for VM access |
| `enable_apim` | `true` | API Management in Internal VNet mode |
| `enable_jumpbox` | `true` | Windows jumpbox VM |
| `enable_agent_vm` | `true` | Linux CI/CD agent VM |

### Hub Service Configuration

| Variable | Type | Default | Description |
|---|---|---|---|
| `firewall_sku_tier` | string | `Standard` | `Standard` or `Premium` (IDPS + TLS inspection) |
| `firewall_network_rules` | list | `[]` | Network rule collections. See `modules/firewall/variables.tf` |
| `firewall_application_rules` | list | `[]` | Application rule collections |
| `app_gateway_sku_name` | string | `WAF_v2` | AGW SKU name |
| `app_gateway_sku_tier` | string | `WAF_v2` | AGW SKU tier |
| `app_gateway_capacity` | number | `2` | Number of AGW instances (autoscaling not configured by default) |
| `app_gateway_backend_pools` | map | `{}` | Map of backend pool name → list of FQDNs |
| `vpn_gateway_sku` | string | `VpnGw1` | VPN Gateway SKU |
| `apim_publisher_name` | string | `My Organisation` | Displayed in the APIM developer portal |
| `apim_publisher_email` | string | `platform@example.com` | APIM admin contact email |
| `apim_sku_name` | string | `Developer_1` | `Developer_1` (non-prod), `Premium_1` (prod) |
| `acr_sku` | string | `Premium` | `Basic`, `Standard`, or `Premium` (Premium needed for private endpoints) |
| `jumpbox_vm_size` | string | `Standard_D2s_v3` | Windows jumpbox VM size |
| `agent_vm_size` | string | `Standard_D4s_v3` | Linux agent VM size |
| `vm_admin_username` | string | `azureadmin` | Local admin username for both VMs |
| `vm_admin_password` | string | `""` | **Pass via `-var` flag. Never store in tfvars.** |
| `vm_ssh_public_key` | string | `""` | SSH public key content for the agent VM |

---

## 11. Spoke Variable Reference

All variables are in `spoke/variables.tf`. Set values in `subscriptions/{env}/values.tfvars`.

### Identity

| Variable | Type | Default | Description |
|---|---|---|---|
| `subscription_id` | string | — | Spoke Azure subscription ID. **Required.** |

### Hub References

These come from `terraform output` after deploying the hub.

| Variable | Type | Description |
|---|---|---|
| `hub_subscription_id` | string | Hub subscription ID. Needed for cross-subscription VNet peering |
| `hub_vnet_id` | string | Full resource ID of the hub VNet |
| `hub_vnet_name` | string | Name of the hub VNet |
| `hub_rg_name` | string | Resource group name containing the hub VNet |
| `hub_firewall_private_ip` | string | Private IP of the hub firewall. Used as the UDR next hop |
| `hub_keyvault_id` | string | Resource ID of the hub Key Vault. Granted read access to app managed identities |
| `link_dns_to_hub_vnet` | bool | When true, spoke DNS zones are also linked to hub VNet so hub VMs can resolve spoke hostnames |

### Naming

| Variable | Type | Default | Description |
|---|---|---|---|
| `org` | string | — | Must match hub `org` |
| `environment` | string | — | `dev`, `staging`, or `prod` |
| `project` | string | `web` | Workload identifier — appears in all spoke resource names |
| `location` | string | `westeurope` | Must match hub `location` |
| `region_short` | string | `we` | Must match hub `region_short` |
| `instance` | string | `001` | Must match hub `instance` |
| `tags` | map(string) | `{}` | Additional tags applied to all spoke resources |

### Spoke Networking

| Variable | Type | Default | Description |
|---|---|---|---|
| `spoke_vnet_cidr` | string | `10.1.0.0/16` | Spoke VNet address space. Must not overlap with hub or other spokes |
| `spoke_subnet_cidrs` | object | See defaults | Individual subnet CIDRs. Change all when changing `spoke_vnet_cidr` |

### Feature Flags

| Variable | Default | Description |
|---|---|---|
| `enable_app_service` | `true` | Linux App Service + web apps |
| `enable_function_app` | `true` | Linux Function Apps (requires `enable_storage = true`) |
| `enable_storage` | `true` | Storage Account with blob and file PEs |
| `enable_redis` | `true` | Azure Cache for Redis |
| `enable_sql_db` | `true` | Azure SQL Database |
| `enable_sql_mi` | `false` | SQL Managed Instance (expensive, 4–6 hr provision time) |
| `enable_service_bus` | `true` | Service Bus namespace |
| `enable_event_grid` | `true` | Event Grid domain |
| `enable_openai` | `false` | Azure OpenAI (requires Microsoft approval) |
| `enable_search` | `true` | Azure AI Search |
| `enable_speech` | `true` | Azure AI Speech |
| `enable_databricks` | `false` | Azure Databricks (expensive) |
| `enable_mysql_flexible` | `true` | MySQL Flexible Server |
| `enable_postgresql` | `true` | PostgreSQL Flexible Server |
| `enable_cosmosdb_nosql` | `true` | CosmosDB NoSQL (SQL API) |
| `enable_cosmosdb_mongo` | `false` | CosmosDB MongoDB API |
| `enable_ai_vision` | `true` | Azure AI Vision (Computer Vision) |
| `enable_ai_foundry` | `false` | Azure AI Foundry / ML workspace |
| `enable_bing_search` | `false` | Bing Search (public endpoint) |
| `enable_container_instance` | `false` | Azure Container Instances |

### Workload Configuration

| Variable | Type | Default | Description |
|---|---|---|---|
| `log_retention_days` | number | `30` | Log Analytics retention. 30 for dev, 90 for prod |
| `app_service_sku` | string | `P1v3` | App Service Plan SKU. e.g., `P1v3`, `P2v3` |
| `app_service_names` | list(string) | `["fe", "be"]` | Short names for each web app |
| `function_app_sku` | string | `EP1` | Function App Plan SKU. e.g., `EP1`, `EP2` |
| `function_app_names` | list(string) | `["proc"]` | Short names for each function app |
| `redis_sku` | string | `Standard` | Redis SKU: `Basic`, `Standard`, `Premium` |
| `redis_capacity` | number | `1` | Redis cache size (0=250MB, 1=1GB, 2=2.5GB…) |
| `redis_family` | string | `C` | `C` for Basic/Standard, `P` for Premium |
| `sql_admin_login` | string | `sqladmin` | SQL Server admin login |
| `sql_admin_password` | string | `""` | **Pass via `-var` flag.** |
| `sql_databases` | map(object) | `{main={S1, 32}}` | Map of database name → `{sku_name, max_size_gb}` |
| `sql_mi_sku` | string | `GP_Gen5` | SQL MI SKU |
| `sql_mi_vcores` | number | `4` | SQL MI vCores |
| `sql_mi_storage_gb` | number | `32` | SQL MI storage in GB |
| `service_bus_sku` | string | `Premium` | Must be `Premium` for private endpoints |
| `service_bus_queues` | list(string) | `[]` | Queue names to create in the namespace |
| `service_bus_topics` | list(string) | `[]` | Topic names to create in the namespace |
| `openai_location` | string | `eastus` | Region for OpenAI (capacity varies by region) |
| `openai_deployments` | map(object) | `{}` | Map of deployment name → model config |
| `search_sku` | string | `standard` | AI Search SKU: `free`, `basic`, `standard`, `standard2`, `standard3` |
| `mysql_admin_login` | string | `mysqladmin` | MySQL admin username |
| `mysql_admin_password` | string | `""` | **Pass via `-var` flag.** |
| `mysql_sku_name` | string | `Standard_D2ds_v4` | MySQL compute SKU |
| `mysql_version` | string | `8.0.21` | MySQL version |
| `mysql_storage_gb` | number | `32` | MySQL storage in GB |
| `postgresql_admin_login` | string | `psqladmin` | PostgreSQL admin username |
| `postgresql_admin_password` | string | `""` | **Pass via `-var` flag.** |
| `postgresql_sku_name` | string | `Standard_D2s_v3` | PostgreSQL compute SKU |
| `postgresql_version` | string | `14` | PostgreSQL version: `11`, `12`, `13`, `14`, `15` |
| `postgresql_storage_mb` | number | `32768` | PostgreSQL storage in MB (32768 = 32 GB) |
| `container_instance_containers` | list(object) | `[]` | Container definitions. Required when `enable_container_instance = true` |

---

## 12. Networking Patterns

Understanding the three networking patterns is critical for knowing which subnet to put services in.

### Pattern A — Private Endpoint (most services)

The service resource itself is NOT in your VNet. A private network interface (private endpoint) is created in `snet-pe` that gets a private IP. Traffic to the service goes through this PE.

```
App → snet-pe (private endpoint NIC) → Service (e.g., Redis, SQL, OpenAI)
```

Services using this pattern: App Service (inbound), Function App (inbound), Redis, SQL Database, Service Bus, Event Grid, OpenAI, AI Search, Speech, AI Vision, CosmosDB, Key Vault, ACR, Storage.

**Required DNS:** A private DNS zone maps the service's public FQDN to the PE private IP. For example, `redis-web-qoc-we-prod-001.redis.cache.windows.net` resolves to `10.31.2.x` inside the VNet.

### Pattern B — VNet Injection (stateful services)

The service resource IS injected into your dedicated subnet. It gets an IP from your subnet's address range directly.

```
App → snet-mysql (server lives here) — no PE needed
```

Services using this pattern: MySQL Flexible Server, PostgreSQL Flexible Server, SQL Managed Instance, Databricks (two subnets), Container Instance, AI Foundry compute.

These subnets must be **delegated** to the service (done automatically in `spoke/main.tf`). The delegation grants the service permission to inject NICs into the subnet.

### Pattern C — VNet Integration (App Service / Function App outbound)

The service uses your subnet for **outbound** traffic only. Inbound still uses a PE (Pattern A). This is Azure's "VNet integration" feature.

```
Inbound:  Client → App Service PE (snet-pe)
Outbound: App Service → snet-app → [UDR] → Hub Firewall → Internet/Azure services
```

The `WEBSITE_VNET_ROUTE_ALL = "1"` setting forces ALL outbound traffic (including RFC 1918) through the integration subnet and then the UDR.

### Pattern D — Public Endpoint (Bing Search only)

Bing Search does not support private endpoints. Traffic goes directly from App Service outbound through the firewall to the Bing Search public API. The API key must be stored in Key Vault.

### UDR and force-tunneling

Every spoke subnet that has `route_table_id` set routes `0.0.0.0/0` → Hub Firewall private IP. This means:
- All internet-bound traffic from App Service, Function App goes through hub firewall inspection
- Azure service traffic tagged with `AzureCloud` service tags also passes through (can be allowed in firewall rules)
- Services in PE subnets (`snet-pe`) do not need UDRs because they respond to the caller, not initiate outbound connections

---

## 13. Feature Flags

Feature flags let you deploy different capabilities per environment without writing different Terraform code. Set them in `subscriptions/{env}/values.tfvars`.

### Dev profile (cost-optimized)

```hcl
enable_app_service        = true
enable_function_app       = true
enable_storage            = true
enable_redis              = true
enable_sql_db             = true
enable_sql_mi             = false   # always off unless specifically needed
enable_service_bus        = true
enable_event_grid         = false
enable_openai             = false   # needs Microsoft quota approval
enable_search             = false
enable_speech             = false
enable_databricks         = false   # expensive
enable_mysql_flexible     = false
enable_postgresql         = false
enable_cosmosdb_nosql     = false
enable_cosmosdb_mongo     = false
enable_ai_vision          = false
enable_ai_foundry         = false
enable_bing_search        = false
enable_container_instance = false
```

### Prod profile (full deployment)

```hcl
# All true except:
enable_sql_mi             = false   # only if you specifically need Managed Instance
enable_cosmosdb_mongo     = false   # only if you use MongoDB API
enable_ai_foundry         = false   # only if you use ML workflows
enable_bing_search        = false   # only if you have Bing Search quota
enable_container_instance = false   # only if you run containerized workloads
```

---

## 14. Environment Customization Guide

### Add more app services

```hcl
# subscriptions/prod/values.tfvars
app_service_names = ["fe", "be", "admin", "api"]
# Creates: app-fe-..., app-be-..., app-admin-..., app-api-...
```

### Add Service Bus queues and topics

```hcl
service_bus_queues = ["orders", "notifications", "payments"]
service_bus_topics = ["events", "audit"]
```

### Configure OpenAI deployments

```hcl
enable_openai   = true
openai_location = "eastus"   # or "swedencentral", "australiaeast"
openai_deployments = {
  gpt4o = {
    model_name    = "gpt-4o"
    model_version = "2024-11-20"
    sku_name      = "GlobalStandard"
    capacity      = 10   # TPM in thousands
  }
  gpt35turbo = {
    model_name    = "gpt-35-turbo"
    model_version = "0613"
    sku_name      = "Standard"
    capacity      = 30
  }
}
```

### Use a different Azure region

Change in both hub and spoke configs:

```hcl
# hub values.tfvars
location     = "eastus"
region_short = "eus"

# spoke values.tfvars  
location     = "eastus"
region_short = "eus"
```

All resource names update automatically: `azfw-qoc-hub-eus-dev-001`, `app-fe-qoc-eus-prod-001`.

### Scale up databases for production

```hcl
# SQL Database
sql_databases = {
  main  = { sku_name = "S3",  max_size_gb = 128 }
  audit = { sku_name = "S1",  max_size_gb = 32  }
}

# MySQL
mysql_sku_name   = "Standard_D8ds_v4"
mysql_storage_gb = 256

# PostgreSQL
postgresql_sku_name    = "Standard_D8s_v3"
postgresql_storage_mb  = 524288   # 512 GB
```

### Deploy a second project on the same hub

Create a new subscriptions folder for the second project's spoke:

```bash
mkdir subscriptions/myproject-prod
```

```hcl
# subscriptions/myproject-prod/values.tfvars
subscription_id = "second-project-prod-subscription-id"
org             = "qoc"
project         = "api"          # different project = different resource names
environment     = "prod"
# ... same hub references as prod spoke ...
```

```hcl
# subscriptions/myproject-prod/backend.tfvars
key = "myproject-prod/terraform.tfstate"   # unique state key
```

Deploy:
```bash
cd spoke/
terraform init -reconfigure -backend-config="../subscriptions/myproject-prod/backend.tfvars"
terraform apply -var-file="../subscriptions/myproject-prod/values.tfvars" ...
```

### Add custom firewall rules

```hcl
# subscriptions/hub-prod/values.tfvars
firewall_network_rules = [
  {
    name     = "AllowOnPremToSpoke"
    priority = 200
    action   = "Allow"
    rules = [
      {
        name                  = "AllowSQLFromOnPrem"
        source_addresses      = ["192.168.1.0/24"]
        destination_addresses = ["10.31.2.0/24"]
        destination_ports     = ["1433"]
        protocols             = ["TCP"]
      }
    ]
  }
]
```

---

## 15. Secrets and Sensitive Values

**Never store passwords or secrets in `.tfvars` files.** Pass them at apply time:

```bash
terraform apply \
  -var-file="../subscriptions/prod/values.tfvars" \
  -var="sql_admin_password=${SQL_PASSWORD}" \
  -var="mysql_admin_password=${MYSQL_PASSWORD}" \
  -var="postgresql_admin_password=${PG_PASSWORD}" \
  -var="vm_admin_password=${VM_PASSWORD}"
```

### In Azure DevOps

Store secrets as **secret pipeline variables** or in **Azure Key Vault** linked to the pipeline library:

```yaml
variables:
  - group: terraform-secrets   # Key Vault-linked variable group

steps:
  - script: |
      terraform apply \
        -var-file="../subscriptions/prod/values.tfvars" \
        -var="sql_admin_password=$(SQL_ADMIN_PASSWORD)"
```

### In GitHub Actions

```yaml
- name: Terraform Apply
  env:
    SQL_PASSWORD: ${{ secrets.SQL_ADMIN_PASSWORD }}
  run: |
    terraform apply \
      -var-file="../subscriptions/prod/values.tfvars" \
      -var="sql_admin_password=$SQL_PASSWORD"
```

### Terraform state contains secrets

The Terraform state file stores all resource attributes including sensitive ones. The state backend (Azure Blob Storage) must have:
- **Private access only** (no public blob access — set by `allow-blob-public-access false`)
- **RBAC access control** — only the pipeline service principal and platform admins should have Contributor on the state storage account
- **Versioning enabled** to recover from accidental state corruption

---

## 16. CI/CD Pipeline Integration

### Azure DevOps pipeline (recommended)

The Agent VM deployed in the hub can run as a self-hosted Azure DevOps agent. This gives your pipeline direct access to spoke VNets through the peering.

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include: [main]

pool:
  name: self-hosted-agents   # points to the hub Agent VM pool

stages:
  - stage: Deploy_Hub_Dev
    jobs:
      - job: TerraformHubDev
        steps:
          - task: AzureCLI@2
            inputs:
              azureSubscription: hub-dev-service-connection
              scriptType: bash
              scriptLocation: inlineScript
              inlineScript: |
                cd terraform/hub
                terraform init -backend-config="../subscriptions/hub-dev/backend.tfvars"
                terraform apply -auto-approve \
                  -var-file="../subscriptions/hub-dev/values.tfvars" \
                  -var="vm_admin_password=$(VM_ADMIN_PASSWORD)"

  - stage: Deploy_Dev_Spoke
    dependsOn: Deploy_Hub_Dev
    jobs:
      - job: TerraformDevSpoke
        steps:
          - task: AzureCLI@2
            inputs:
              azureSubscription: dev-service-connection
              scriptType: bash
              scriptLocation: inlineScript
              inlineScript: |
                cd terraform/spoke
                terraform init -reconfigure \
                  -backend-config="../subscriptions/dev/backend.tfvars"
                terraform apply -auto-approve \
                  -var-file="../subscriptions/dev/values.tfvars" \
                  -var="sql_admin_password=$(SQL_ADMIN_PASSWORD)"
```

### Service principal permissions

Create one service principal per subscription pair (hub + spoke):

```bash
# Create SP for dev environment (needs access to both hub-dev and dev subscriptions)
az ad sp create-for-rbac \
  --name "sp-terraform-dev" \
  --role Contributor \
  --scopes \
    /subscriptions/<hub-dev-subscription-id> \
    /subscriptions/<dev-subscription-id>

# Also needs User Access Administrator to create role assignments
az role assignment create \
  --assignee <sp-app-id> \
  --role "User Access Administrator" \
  --scope /subscriptions/<hub-dev-subscription-id>
az role assignment create \
  --assignee <sp-app-id> \
  --role "User Access Administrator" \
  --scope /subscriptions/<dev-subscription-id>
```

---

## 17. Common Operations

### Check what Terraform will change

```bash
cd spoke/
terraform init -reconfigure -backend-config="../subscriptions/prod/backend.tfvars"
terraform plan -var-file="../subscriptions/prod/values.tfvars" \
               -var="sql_admin_password=dummy"
```

### Update a single resource

```bash
# Only apply changes to the Redis module
terraform apply -target=module.redis_cache -var-file="../subscriptions/prod/values.tfvars" ...
```

### Import an existing resource

```bash
# Import an existing resource group into Terraform state
terraform import \
  -var-file="../subscriptions/prod/values.tfvars" \
  module.spoke_rg.azurerm_resource_group.this \
  /subscriptions/<sub-id>/resourceGroups/rg-web-qoc-we-prod-001
```

### Refresh state without applying changes

```bash
terraform refresh -var-file="../subscriptions/prod/values.tfvars" \
                  -var="sql_admin_password=dummy"
```

### View all outputs

```bash
# After deploying hub — these values go into spoke values.tfvars
cd hub/
terraform init -reconfigure -backend-config="../subscriptions/hub-prod/backend.tfvars"
terraform output
```

### Upgrade the provider

```hcl
# In hub/providers.tf and spoke/providers.tf — change the version constraint
required_providers {
  azurerm = {
    source  = "hashicorp/azurerm"
    version = "~> 4.0"   # was ~> 3.110
  }
}
```

Then run `terraform init -upgrade` and fix any breaking changes.

---

## 18. Troubleshooting

### `Blocks of type 'scale' are not expected here`

This is a known azurerm provider schema issue with older IDE/linter plugins. The `azurerm_cognitive_deployment` resource uses `sku {}` (not `scale {}`):

```hcl
# WRONG (old schema):
scale {
  type     = "Standard"
  capacity = 10
}

# CORRECT (azurerm >= 3.71):
sku {
  name     = "Standard"
  capacity = 10
}
```

### `custom_subdomain_name` is required

When deploying any Cognitive Services resource (OpenAI, Speech, Vision) with `public_network_access_enabled = false`, the `custom_subdomain_name` attribute is mandatory. Without it, the private endpoint DNS resolution fails. All three modules in this template set it to `var.name`.

### Databricks workspace fails with NSG association error

The Databricks workspace needs the **subnet resource ID** (not the NSG resource ID) for `public_subnet_network_security_group_association_id`. In azurerm, the `azurerm_subnet_network_security_group_association` resource ID equals the subnet ID. The spoke correctly passes `module.snet_dbk_pub.id` (subnet ID).

### `terraform init` fails with backend error

Run with `-reconfigure` when switching between environments:

```bash
terraform init -reconfigure -backend-config="../subscriptions/staging/backend.tfvars"
```

### Private endpoint DNS not resolving

Check that:
1. The private DNS zone exists and is linked to the VNet
2. The `link_dns_to_hub_vnet = true` flag is set if you're testing from a hub VM
3. The private endpoint is in the `snet-pe` subnet
4. `private_endpoint_network_policies_enabled = false` is set on `snet-pe` (done automatically)

### SQL MI takes too long / times out

SQL Managed Instance takes 4–6 hours to provision. This is expected and not a Terraform issue. Run `terraform apply` and wait. If it times out, re-run — Terraform will pick up where it left off.

### App Service can't reach internal services

Check:
1. `WEBSITE_VNET_ROUTE_ALL = "1"` is set in app settings (done automatically)
2. UDR is attached to `snet-app` (done automatically)
3. Hub firewall has a rule allowing the spoke subnet to reach the destination port
4. The target service has a private endpoint and its DNS zone is linked to the spoke VNet

### APIM health check fails

APIM in Internal VNet mode requires port 3443 inbound from the `ApiManagement` service tag. The hub creates `nsg_apim` with this rule. Verify the NSG is associated with `snet-apim`.

### MySQL/PostgreSQL cannot connect

These use VNet injection, not private endpoints. Verify:
1. The delegated subnet (`snet-mysql` or `snet-psql`) is correctly delegated
2. The private DNS zone (`privatelink.mysql.database.azure.com` or `privatelink.postgres.database.azure.com`) is linked to the spoke VNet
3. Connect using the server FQDN, not the IP address — the FQDN resolves correctly inside the VNet via private DNS

---

*Managed by Terraform — provider: `hashicorp/azurerm ~> 3.110` — Terraform `>= 1.5.0`*
