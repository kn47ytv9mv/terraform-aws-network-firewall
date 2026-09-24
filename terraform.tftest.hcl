mock_provider "aws" {
  mock_resource "aws_networkfirewall_firewall" {
    defaults = {
      arn = "arn:aws:network-firewall:us-east-1:123456789012:firewall/mock"
    }
  }
}

run "invalid_log_type_is_rejected" {
  command = plan

  variables {
    firewall_policy_arn = "arn:aws:network-firewall:us-east-1:123456789012:firewall-policy/example"
    vpc_id              = "vpc-0123456789abcdef0"
    subnet_mapping = [
      { subnet_id = "subnet-0123456789abcdef0" },
    ]
    logging_destinations = [
      { log_type = "EVERYTHING", log_destination_type = "S3", log_destination = { bucketName = "fw-logs" } },
    ]
  }

  expect_failures = [var.logging_destinations]
}

run "invalid_log_destination_type_is_rejected" {
  command = plan

  variables {
    firewall_policy_arn = "arn:aws:network-firewall:us-east-1:123456789012:firewall-policy/example"
    vpc_id              = "vpc-0123456789abcdef0"
    subnet_mapping = [
      { subnet_id = "subnet-0123456789abcdef0" },
    ]
    logging_destinations = [
      { log_type = "FLOW", log_destination_type = "Syslog", log_destination = { bucketName = "fw-logs" } },
    ]
  }

  expect_failures = [var.logging_destinations]
}

run "required_arguments_pass_through" {
  command = plan

  variables {
    firewall_policy_arn = "arn:aws:network-firewall:us-east-1:123456789012:firewall-policy/example"
    vpc_id              = "vpc-0123456789abcdef0"
    subnet_mapping = [
      { subnet_id = "subnet-0123456789abcdef0" },
    ]
  }

  assert {
    condition     = aws_networkfirewall_firewall.resource.firewall_policy_arn == "arn:aws:network-firewall:us-east-1:123456789012:firewall-policy/example"
    error_message = "firewall_policy_arn should pass through unchanged."
  }

  assert {
    condition     = aws_networkfirewall_firewall.resource.vpc_id == "vpc-0123456789abcdef0"
    error_message = "vpc_id should pass through unchanged."
  }
}

run "subnet_mapping_renders_one_block_per_entry" {
  command = apply

  variables {
    firewall_policy_arn = "arn:aws:network-firewall:us-east-1:123456789012:firewall-policy/example"
    vpc_id              = "vpc-0123456789abcdef0"
    subnet_mapping = [
      { subnet_id = "subnet-0123456789abcdef0" },
      { subnet_id = "subnet-0123456789abcdef1", ip_address_type = "IPV4" },
    ]
  }

  assert {
    condition     = length(aws_networkfirewall_firewall.resource.subnet_mapping) == 2
    error_message = "Two subnet_mapping entries should render exactly two subnet_mapping blocks."
  }

  assert {
    condition     = anytrue([for m in aws_networkfirewall_firewall.resource.subnet_mapping : m.ip_address_type == "IPV4"])
    error_message = "subnet_mapping.ip_address_type should pass through unchanged."
  }
}

run "protection_flags_pass_through" {
  command = plan

  variables {
    firewall_policy_arn               = "arn:aws:network-firewall:us-east-1:123456789012:firewall-policy/example"
    vpc_id                            = "vpc-0123456789abcdef0"
    subnet_mapping                    = [{ subnet_id = "subnet-0123456789abcdef0" }]
    delete_protection                 = true
    firewall_policy_change_protection = true
    subnet_change_protection          = true
  }

  assert {
    condition     = aws_networkfirewall_firewall.resource.delete_protection == true
    error_message = "delete_protection should pass through unchanged."
  }

  assert {
    condition     = aws_networkfirewall_firewall.resource.firewall_policy_change_protection == true
    error_message = "firewall_policy_change_protection should pass through unchanged."
  }

  assert {
    condition     = aws_networkfirewall_firewall.resource.subnet_change_protection == true
    error_message = "subnet_change_protection should pass through unchanged."
  }
}

run "tags_pass_through" {
  command = plan

  variables {
    firewall_policy_arn = "arn:aws:network-firewall:us-east-1:123456789012:firewall-policy/example"
    vpc_id              = "vpc-0123456789abcdef0"
    subnet_mapping      = [{ subnet_id = "subnet-0123456789abcdef0" }]
    tags = {
      Name = "example-firewall"
    }
  }

  assert {
    condition     = aws_networkfirewall_firewall.resource.tags.Name == "example-firewall"
    error_message = "tags should pass through unchanged."
  }
}

run "no_logging_by_default" {
  command = plan

  variables {
    firewall_policy_arn = "arn:aws:network-firewall:us-east-1:123456789012:firewall-policy/example"
    vpc_id              = "vpc-0123456789abcdef0"
    subnet_mapping = [
      { subnet_id = "subnet-0123456789abcdef0" },
    ]
  }

  assert {
    condition     = length(aws_networkfirewall_logging_configuration.resource) == 0
    error_message = "Leaving logging_destinations empty should create no logging configuration."
  }
}

run "supplying_destinations_enables_logging" {
  command = plan

  variables {
    firewall_policy_arn = "arn:aws:network-firewall:us-east-1:123456789012:firewall-policy/example"
    vpc_id              = "vpc-0123456789abcdef0"
    subnet_mapping = [
      { subnet_id = "subnet-0123456789abcdef0" },
    ]
    logging_destinations = [
      { log_type = "FLOW", log_destination_type = "S3", log_destination = { bucketName = "fw-logs" } },
      { log_type = "ALERT", log_destination_type = "CloudWatchLogs", log_destination = { logGroup = "/aws/nfw/alerts" } },
    ]
  }

  assert {
    condition     = length(aws_networkfirewall_logging_configuration.resource) == 1
    error_message = "Supplying destinations should create exactly one logging configuration resource."
  }

  assert {
    condition     = length(aws_networkfirewall_logging_configuration.resource[0].logging_configuration[0].log_destination_config) == 2
    error_message = "Each logging_destinations entry should produce one log_destination_config block."
  }
}

run "readme_default_example" {
  command = plan

  variables {
    firewall_policy_arn = "arn:aws:network-firewall:us-east-1:123456789012:firewall-policy/example"
    vpc_id              = "vpc-0123456789abcdef0"
    subnet_mapping = [
      { subnet_id = "subnet-0123456789abcdef0" },
      { subnet_id = "subnet-0123456789abcdef1" },
    ]
  }
}

run "readme_protected_firewall_example" {
  command = plan

  variables {
    firewall_policy_arn = "arn:aws:network-firewall:us-east-1:123456789012:firewall-policy/example"
    vpc_id              = "vpc-0123456789abcdef0"

    subnet_mapping = [
      { subnet_id = "subnet-0123456789abcdef0" },
      { subnet_id = "subnet-0123456789abcdef1" },
    ]

    delete_protection                 = true
    firewall_policy_change_protection = true
  }
}
