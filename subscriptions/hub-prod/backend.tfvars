# Terraform remote state for hub-prod subscription
# Pre-create this storage account before running terraform init
resource_group_name  = "rg-tfstate-qoc-hub-we-prod-001"
storage_account_name = "stqochubweprodtfstate001"
container_name       = "tfstate"
key                  = "hub-prod/terraform.tfstate"
