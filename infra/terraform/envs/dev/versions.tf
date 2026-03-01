terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "hq-tfstate-kyriakos-2026-eu-central-1"
    key            = "dev/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "hq-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region
}
