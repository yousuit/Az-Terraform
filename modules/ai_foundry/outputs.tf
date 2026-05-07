output "id"                  { value = azurerm_machine_learning_workspace.this.id }
output "name"                { value = azurerm_machine_learning_workspace.this.name }
output "workspace_id"        { value = azurerm_machine_learning_workspace.this.workspace_id }
output "discovery_url"       { value = azurerm_machine_learning_workspace.this.discovery_url }
output "principal_id"        { value = azurerm_machine_learning_workspace.this.identity[0].principal_id }
output "compute_cluster_id"  { value = azurerm_machine_learning_compute_cluster.cpu.id }
