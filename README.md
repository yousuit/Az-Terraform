# Azure Hub-and-Spoke Terraform Template

## What this template does

This Terraform template deploys a secure Azure hub-and-spoke network with all the cloud services you need for a project. You run it once for each Azure subscription — hub first, then dev, staging, and prod separately. Everything is private by default: services talk to each other over Azure's internal network, not the internet.

---

## How it is organized

```
terraform/
├── hub/                    ← Run this against the Hub subscription
├── spoke/                  ← Run this against Dev, Staging, or Prod subscription
├── modules/                ← Reusable building blocks (don't touch these)
└── subscriptions/
    ├── hub/                ← Hub config values + state storage location
    ├── dev/                ← Dev config values + state storage location
    ├── staging/            ← Staging config values + state storage location
    └── prod/               ← Prod config values + state storage location
```

**You only ever edit files inside `subscriptions/`.** Everything in `hub/` and `spoke/` is the engine — you don't change those for different projects or environments.

---

## The two-part architecture

### Hub (shared infrastructure — deployed once)

The hub subscription holds the network backbone that every environment uses:

| What gets created | Name example | What it does |
|---|---|---|
| Hub resource group | `rg-qoc-hub-we-001` | Container for all hub resources |
| DNS resource group | `rg-pdns-qoc-hub-we-001` | Container for private DNS zones |
| Hub virtual network | `vnet-qoc-hub-we-001` | The central network (10.0.0.0/16) |
| Azure Firewall | `azfw-qoc-hub-we-001` | All outbound internet traffic goes through here |
| Application Gateway (WAF) | `agw-qoc-hub-we-001` | Entry point for inbound web traffic |
| Bastion | `bas-qoc-hub-we-001` | Secure SSH/RDP to VMs without public IPs |
| API Management | `apim-qoc-hub-we-001` | Internal API gateway (no public exposure) |
| Key Vault | `kv-qoc-hub-we-001` | Platform secrets, certificates |
| Container Registry | `acr-qoc-hub-we-001` | Shared Docker image registry |
| Jumpbox VM | `vm-jmp-qoc-hub-we-001` | Windows VM for admin access |
| Agent VM | `vm-agt-qoc-hub-we-001` | Linux VM for CI/CD pipelines |

### Spoke (workload environment — deployed per subscription)

Each environment (dev, staging, prod) gets its own spoke subscription with:

| What gets created | Name example | What it does |
|---|---|---|
| Spoke resource group | `rg-web-qoc-we-prod-001` | Container for all workload resources |
| DNS resource group | `rg-pdns-qoc-we-prod-001` | Private DNS zones for this environment |
| Spoke virtual network | `vnet-qoc-we-prod-001` | Workload network, peered to hub |
| App Services | `app-fe-qoc-we-prod-001` | Your web apps (one per name in app_service_names) |
| Function Apps | `func-proc-qoc-we-prod-001` | Your functions (one per name in function_app_names) |
| SQL Database | `sql-web-qoc-we-prod-001` | Azure SQL Server |
| Redis Cache | `redis-web-qoc-we-prod-001` | Caching layer |
| Service Bus | `sb-web-qoc-we-prod-001` | Message queuing |
| Storage Account | `stqocwebweprod001` | Blob/file storage |
| + 15 more services | (all toggleable via feature flags) | |

All spoke workloads connect to the internet through the hub firewall. All inbound connections go through private endpoints — no service has a public IP.

---

## Naming convention

Every resource name is built from the same four pieces:

```
{resource-type}-{workload}-{org}-{region}-{environment}-{instance}
```

**Hub example:** `azfw-qoc-hub-we-001`
- `azfw` = Azure Firewall
- `qoc` = your org code
- `hub` = this is a hub resource
- `we` = West Europe
- `001` = first instance

**Spoke example:** `app-fe-qoc-we-prod-001`
- `app` = App Service
- `fe` = frontend (from your app_service_names list)
- `qoc` = your org code
- `we` = West Europe
- `prod` = production environment
- `001` = first instance

**To change the naming for a new project or client**, you only change `org`, `project`, `region_short`, and `instance` in the `values.tfvars` files. The names rebuild automatically.

---

## Step-by-step: deploying for the first time

### Step 1 — Fill in hub values

Open `subscriptions/hub/values.tfvars` and replace the placeholder values:

```hcl
subscription_id = "your-hub-azure-subscription-id"
org             = "qoc"       # your 2-4 letter org code — used in ALL resource names
location        = "westeurope"
region_short    = "we"
instance        = "001"
```

Open `subscriptions/hub/backend.tfvars` and set where to store Terraform state:

```hcl
resource_group_name  = "rg-tfstate-qoc-hub-we-001"   # pre-create this RG first
storage_account_name = "stqochubwetfstate001"          # pre-create this storage account
container_name       = "tfstate"
key                  = "hub/terraform.tfstate"
```

### Step 2 — Deploy hub

```bash
az login
az account set --subscription <hub-subscription-id>

cd hub/
terraform init -backend-config="../subscriptions/hub/backend.tfvars"
terraform apply -var-file="../subscriptions/hub/values.tfvars" \
                -var="vm_admin_password=YourSecureP@ssword1"
```

After it finishes, run `terraform output` and copy the values shown. You will need them for the spoke.

### Step 3 — Fill in spoke values

Open `subscriptions/dev/values.tfvars` (or staging / prod). Fill in the hub references from the output you just copied:

```hcl
subscription_id     = "your-dev-azure-subscription-id"

# Paste from hub terraform output:
hub_subscription_id     = "your-hub-subscription-id"
hub_vnet_id             = "/subscriptions/.../vnet-qoc-hub-we-001"
hub_vnet_name           = "vnet-qoc-hub-we-001"
hub_rg_name             = "rg-qoc-hub-we-001"
hub_firewall_private_ip = "10.0.0.4"
hub_keyvault_id         = "/subscriptions/.../kv-qoc-hub-we-001"
```

Then set the environment-specific values:

```hcl
org          = "qoc"       # must match hub
environment  = "dev"       # dev | staging | prod
project      = "web"       # workload name — appears in all resource names
region_short = "we"        # must match hub
```

### Step 4 — Deploy the spoke

```bash
az login
az account set --subscription <dev-subscription-id>

cd spoke/
terraform init -backend-config="../subscriptions/dev/backend.tfvars"
terraform apply -var-file="../subscriptions/dev/values.tfvars" \
                -var="sql_admin_password=YourSecureP@ssword1"
```

Repeat steps 3–4 for staging and prod using their respective files.

---

## Where to update values for different deployments

### Different client / org code

Change `org` in `subscriptions/hub/values.tfvars` AND in the spoke `values.tfvars` files:
```hcl
org = "abc"   # was "qoc"
```
All resource names rebuild: `azfw-abc-hub-we-001`, `app-fe-abc-we-prod-001`, etc.

### Different project on the same hub

Create a new spoke folder and point it at the same hub:
```
subscriptions/
└── myproject-prod/
    ├── values.tfvars    ← set project = "api"
    └── backend.tfvars   ← use a unique state key: "myproject-prod/terraform.tfstate"
```
Deploy using:
```bash
cd spoke/
terraform init -reconfigure -backend-config="../subscriptions/myproject-prod/backend.tfvars"
terraform apply -var-file="../subscriptions/myproject-prod/values.tfvars" ...
```

### Different Azure region

Update in both hub and spoke values.tfvars:
```hcl
location     = "eastus"
region_short = "eus"
```
All names update: `azfw-qoc-hub-eus-001`, `app-fe-qoc-eus-prod-001`, etc.

### Turn services on or off

Every service has a feature flag. Set it in the spoke `values.tfvars`:
```hcl
enable_openai      = true    # off by default (needs Microsoft approval)
enable_databricks  = false   # expensive — keep off in dev
enable_sql_mi      = false   # very expensive — off unless specifically needed
```

### Scale up for production

Just change the SKU variables in `subscriptions/prod/values.tfvars`:
```hcl
app_service_sku    = "P2v3"     # dev uses P1v3
redis_sku          = "Premium"  # dev uses Standard
log_retention_days = 90         # dev uses 30
```

### Add or remove app names

The `app_service_names` list controls how many App Services are deployed and what they're called:
```hcl
app_service_names = ["fe", "be", "admin"]
# Creates: app-fe-qoc-we-prod-001
#          app-be-qoc-we-prod-001
#          app-admin-qoc-we-prod-001
```

Same pattern for function apps:
```hcl
function_app_names = ["proc", "notifier", "scheduler"]
# Creates: func-proc-qoc-we-prod-001
#          func-notifier-qoc-we-prod-001
#          func-scheduler-qoc-we-prod-001
```

### Different CIDRs per environment

Each environment must use a non-overlapping IP range so they can be peered in future:
```
hub:     10.0.0.0/16
dev:     10.1.0.0/16
staging: 10.3.0.0/16
prod:    10.2.0.0/16
```
Change in the spoke `values.tfvars`:
```hcl
spoke_vnet_cidr = "10.1.0.0/16"
```

---

## Quick reference: which file controls what

| What you want to change | File to edit |
|---|---|
| Hub subscription ID | `subscriptions/hub/values.tfvars` |
| Org code / naming | `subscriptions/hub/values.tfvars` + spoke `values.tfvars` |
| Hub services on/off (firewall, bastion, APIM…) | `subscriptions/hub/values.tfvars` |
| APIM publisher name/email | `subscriptions/hub/values.tfvars` |
| Spoke subscription ID | `subscriptions/<env>/values.tfvars` |
| Project name | `subscriptions/<env>/values.tfvars` → `project` |
| Environment (dev/staging/prod) | `subscriptions/<env>/values.tfvars` → `environment` |
| Spoke services on/off | `subscriptions/<env>/values.tfvars` → `enable_*` flags |
| App Service names | `subscriptions/<env>/values.tfvars` → `app_service_names` |
| Function App names | `subscriptions/<env>/values.tfvars` → `function_app_names` |
| SKU sizes | `subscriptions/<env>/values.tfvars` → `*_sku` variables |
| IP address ranges | `subscriptions/<env>/values.tfvars` → `spoke_vnet_cidr` + `spoke_subnet_cidrs` |
| Azure region | `subscriptions/<env>/values.tfvars` → `location` + `region_short` |
| Where state is stored | `subscriptions/<env>/backend.tfvars` |
| Secrets (passwords, keys) | Pass as `-var` flags — never store in files |

---

## Secrets — never store these in files

These must be passed at apply time, not written into any `.tfvars` file:

```bash
# Hub
-var="vm_admin_password=..."

# Spoke
-var="sql_admin_password=..."
-var="mysql_admin_password=..."
-var="postgresql_admin_password=..."
```

In a CI/CD pipeline, store them as secret pipeline variables and inject them:
```yaml
-var="sql_admin_password=$(SQL_ADMIN_PASSWORD)"
```

---

## What changed from the previous version

| Old | New | Why |
|---|---|---|
| Single `terraform apply` for everything | Separate `hub/` and `spoke/` roots | Each subscription needs its own state and auth |
| `tenants/` folder | `subscriptions/` folder | You target subscriptions now, not tenants |
| `tenant_id` in tfvars | Removed | `az login` handles authentication — no hardcoded tenant |
| `tenant_name` variable | `org` variable | Clearer name for what it does |
| Names like `qfweuwebdev001app001` | Names like `app-fe-qoc-we-prod-001` | Matches the agreed naming standard |
| Single `environments/*.tfvars` | `subscriptions/<env>/values.tfvars` | One file per subscription — no merging two files |
| Hub and spoke in same VNet + RG | Hub and spoke in separate subscriptions | True isolation per environment, separate billing |
| DNS zones in hub for all services | DNS zones in spoke for workloads | Each spoke is self-contained; hub DNS only covers hub services |
| App/func names: `qfweuwebdev001app001-fe` | App/func names: `app-fe-qoc-we-prod-001` | Name comes first, suffix describes the context |

---

## Private endpoint vs VNet injection — which services use which

Some services connect to the VNet differently. It matters because they need different subnet types.

**Private endpoint** (most services — uses `snet-pe`):
- App Service inbound, Function App inbound, Redis, SQL Database, Service Bus, Event Grid, OpenAI, AI Search, Speech, AI Vision, CosmosDB

**VNet injection into a dedicated delegated subnet** (the service IS in your subnet):
- MySQL Flexible → `snet-mysql` (delegation: Microsoft.DBforMySQL)
- PostgreSQL Flexible → `snet-psql` (delegation: Microsoft.DBforPostgreSQL)
- SQL Managed Instance → `snet-sqlmi` (delegation: Microsoft.Sql/managedInstances)
- Databricks → `snet-dbkpub` + `snet-dbkprv` (delegation: Microsoft.Databricks)
- Container Instance → `snet-aci` (delegation: Microsoft.ContainerInstance)
- AI Foundry compute → `snet-aif`

**VNet integration outbound only** (service routes its outbound traffic through your subnet):
- App Service outbound → `snet-app`
- Function App outbound → `snet-func`

**No VNet** (public endpoint, billed per call):
- Bing Search
