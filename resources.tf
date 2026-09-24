resource "random_uuid" "resource" {}

resource "aws_networkfirewall_firewall" "resource" {
  name                = coalesce(var.name, random_uuid.resource.id)
  description         = var.description
  firewall_policy_arn = var.firewall_policy_arn
  vpc_id              = var.vpc_id

  dynamic "subnet_mapping" {
    for_each = var.subnet_mapping

    content {
      subnet_id       = subnet_mapping.value.subnet_id
      ip_address_type = subnet_mapping.value.ip_address_type
    }
  }

  delete_protection                 = var.delete_protection
  firewall_policy_change_protection = var.firewall_policy_change_protection
  subnet_change_protection          = var.subnet_change_protection

  tags = var.tags
}

resource "aws_networkfirewall_logging_configuration" "resource" {
  count = length(var.logging_destinations) > 0 ? 1 : 0

  firewall_arn = aws_networkfirewall_firewall.resource.arn

  logging_configuration {
    dynamic "log_destination_config" {
      for_each = var.logging_destinations

      content {
        log_type             = log_destination_config.value.log_type
        log_destination_type = log_destination_config.value.log_destination_type
        log_destination      = log_destination_config.value.log_destination
      }
    }
  }
}

output "id" {
  description = "The ID of the firewall."
  value       = aws_networkfirewall_firewall.resource.id
}

output "name" {
  description = "The name of the firewall."
  value       = aws_networkfirewall_firewall.resource.name
}

output "arn" {
  description = "The ARN of the firewall."
  value       = aws_networkfirewall_firewall.resource.arn
}

output "firewall_status" {
  description = "Sync status of the firewall's endpoints per availability zone, including each endpoint's ID — needed to add a route through the firewall in each subnet's route table."
  value       = aws_networkfirewall_firewall.resource.firewall_status
}
