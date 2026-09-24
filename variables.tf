variable "name" {
  default     = null
  description = "Name of the firewall. If null, a unique name is generated."
}

variable "description" {
  default     = null
  description = "A description of the firewall."
}

variable "firewall_policy_arn" {
  default     = null
  description = "The ARN of the firewall policy this firewall enforces, from terraform-aws-network-firewall-policy's arn output."
}

variable "vpc_id" {
  default     = null
  description = "The ID of the VPC to deploy the firewall's endpoints into."
}

variable "subnet_mapping" {
  default     = []
  description = "Subnets to deploy a firewall endpoint into, one per availability zone — AWS creates one ENI per entry, and every subnet routing through this firewall needs an entry for its own AZ."
  type = list(object({
    subnet_id       = string
    ip_address_type = optional(string)
  }))
}

variable "delete_protection" {
  default     = null
  description = "Whether to prevent the firewall from being deleted while this is true. If null, AWS's own default (false) applies."
}

variable "firewall_policy_change_protection" {
  default     = null
  description = "Whether to prevent firewall_policy_arn from being changed while this is true. If null, AWS's own default (false) applies."
}

variable "subnet_change_protection" {
  default     = null
  description = "Whether to prevent subnet_mapping from being changed while this is true. If null, AWS's own default (false) applies."
}

variable "logging_destinations" {
  default     = []
  description = "Logs streamed off the firewall. log_type is 'FLOW' (every connection the firewall sees) or 'ALERT' (only traffic a stateful rule acted on); TLS inspection adds 'TLS'. log_destination_type is 'S3', 'CloudWatchLogs', or 'KinesisDataFirehose'. log_destination is a map whose keys depend on that type — 'bucketName' (and optional 'prefix') for S3, 'logGroup' for CloudWatch Logs, 'deliveryStream' for Firehose. Supplying a destination enables logging automatically. If empty, the firewall logs nothing and its rule matches are invisible."
  type = list(object({
    log_type             = string
    log_destination_type = string
    log_destination      = map(string)
  }))

  validation {
    condition     = alltrue([for l in var.logging_destinations : contains(["FLOW", "ALERT", "TLS"], l.log_type)])
    error_message = "A logging destination's log_type must be 'FLOW', 'ALERT', or 'TLS'."
  }

  validation {
    condition     = alltrue([for l in var.logging_destinations : contains(["S3", "CloudWatchLogs", "KinesisDataFirehose"], l.log_destination_type)])
    error_message = "A logging destination's log_destination_type must be 'S3', 'CloudWatchLogs', or 'KinesisDataFirehose'."
  }
}

variable "tags" {
  default     = null
  description = "A map of tags to assign to the firewall."
}
