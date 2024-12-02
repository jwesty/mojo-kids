variable "aws_region" {
  default = "us-east-1"
}

variable "region" {
  default = "us-east-1"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "mojo-kids"
}

variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
  default     = "dev"
}

variable "jwt_secret" {
  default = "your-secret-key"
}