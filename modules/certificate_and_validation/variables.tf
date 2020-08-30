variable "domain_names" {
  type        = list(string)
  description = "First is the domain name for which the certificate will be issued, the rest are subject alternative names."
}

variable "zone_id" {
  type        = string
  description = "ID of the Route53 hosted zone"
}
