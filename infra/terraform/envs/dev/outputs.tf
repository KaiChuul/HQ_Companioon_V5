output "dev_instance_id" {
  description = "EC2 instance ID (use with: aws ssm start-session --target <id>)"
  value       = aws_instance.dev.id
}

output "dev_public_ip" {
  description = "Elastic IP assigned to the dev EC2 instance"
  value       = aws_eip.dev.public_ip
}

output "pages_url" {
  description = "Default Cloudflare Pages URL (before custom domain propagates)"
  value       = "https://${var.cf_pages_project_name}.pages.dev"
}

output "app_url" {
  description = "Frontend — live at custom domain"
  value       = "https://hqv2.${var.cf_zone_name}"
}

output "api_url" {
  description = "Backend API / WebSocket endpoint"
  value       = "https://api.hqv2.${var.cf_zone_name}"
}

output "wake_url" {
  description = "Lambda Function URL to wake/check the EC2 (set as VITE_WAKE_URL)"
  value       = aws_lambda_function_url.wake.function_url
}
