terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.80.0"
    }
  }
  required_version = "~> 1.10"
  # backend "s3" {
  #   bucket = "xxxx"
  #   key = "last-accessed.tfstate"
  #   region = "ap-southeast-1"
  #   encrypt = true
  #   use_lockfile = true # S3 native locking
  # }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = local.common_tags
  }
}