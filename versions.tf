terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.11.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.3"
    }
  }
  required_version = ">= 1.1.3"
}
