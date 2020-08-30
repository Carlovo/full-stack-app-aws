variable "hosted_zone_id" {
  type        = string
  description = "ID of the route53 hosted zone"
}

variable "dns_record_name" {
  type        = string
  description = "DNS record name"
}

variable "alias_domain_name" {
  type        = string
  description = "Domain name of the resource you want to alias"
}

variable "alias_hosted_zone_id" {
  type        = string
  description = "Hosted zone id of the resource you want to alias"
}
