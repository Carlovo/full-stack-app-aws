# There are more data blocks in the other .tf files,
# but those do not point to resources already deployed.

# There is no way to register a domain in AWS through Terraform,
# so this would have to be done in advance with the console.
data "aws_route53_zone" "selected" {
  count = var.alternate_domain_name == "" ? 0 : 1

  name = "${var.alternate_domain_name}."
}
