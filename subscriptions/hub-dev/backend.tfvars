# Terraform remote state for hub-dev subscription
# Pre-create this storage account before running terraform init
resource_group_name  = "rg-tfstate-qoc-hub-we-dev-001"
storage_account_name = "stqochubwedevtfstate001"
container_name       = "tfstate"
key                  = "hub-dev/terraform.tfstate"
