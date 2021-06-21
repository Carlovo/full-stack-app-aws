# CloudFront accepts only ACM certificates from US-EAST-1
provider "aws" {
  alias  = "useast1"
  region = "us-east-1"
}
