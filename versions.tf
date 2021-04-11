terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.33.0"
    }
  }
  required_version = ">= 0.14"
}
