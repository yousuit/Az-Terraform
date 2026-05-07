# Terraform remote state for hub subscription
# Storage account must exist before running terraform init
resource_group_name  = "rg-tfstate-qoc-hub-we-001"
storage_account_name = "stqochubwetfstate001"
container_name       = "tfstate"
key                  = "hub/terraform.tfstate"
