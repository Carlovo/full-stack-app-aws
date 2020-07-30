variable "alternate_domain_name" {
  type        = string
  default     = ""
  description = "Domain name of a HostedZone created by the Route53 Registrar, without trailing '.'"
}

locals {
  alternate_domain_name_www = "www.${var.alternate_domain_name}"
}
