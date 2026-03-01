variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name (dev / staging / prod)"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type for the dev server"
  type        = string
  default     = "t3.micro"
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID (find in CF dashboard → right sidebar)"
  type        = string
}

variable "cf_zone_name" {
  description = "Cloudflare zone root domain"
  type        = string
  default     = "savvy-des.com"
}

variable "cf_pages_project_name" {
  description = "Cloudflare Pages project name"
  type        = string
  default     = "hq-companion-dev"
}

variable "github_repo" {
  description = "GitHub repository (owner/repo) — must be public for EC2 to clone"
  type        = string
  default     = "KaiChuul/HQ_Companioon_V5"
}
