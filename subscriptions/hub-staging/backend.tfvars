# Terraform remote state for hub-staging subscription
# Pre-create this storage account before running terraform init
resource_group_name  = "rg-tfstate-qoc-hub-we-staging-001"
storage_account_name = "stqochubwestagingtfstate001"
container_name       = "tfstate"
key                  = "hub-staging/terraform.tfstate"
