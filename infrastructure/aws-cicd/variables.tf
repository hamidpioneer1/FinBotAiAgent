# Variables for FinBotAiAgent CI/CD infrastructure

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.aws_region))
    error_message = "AWS region must be a valid region identifier."
  }
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "finbotaiagent"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "github_owner" {
  description = "GitHub repository owner (username or organization)"
  type        = string
  
  validation {
    condition     = length(var.github_owner) > 0
    error_message = "GitHub owner cannot be empty."
  }
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "FinBotAiAgent"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.github_repo))
    error_message = "GitHub repository name must contain only alphanumeric characters, dots, underscores, and hyphens."
  }
}

variable "github_branch" {
  description = "GitHub branch to monitor for changes"
  type        = string
  default     = "main"
  
  validation {
    condition     = length(var.github_branch) > 0
    error_message = "GitHub branch cannot be empty."
  }
}

variable "github_token" {
  description = "GitHub personal access token for CodePipeline"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.github_token) > 0
    error_message = "GitHub token cannot be empty."
  }
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster where the service will be deployed"
  type        = string
  default     = "finbotaiagent-cluster"
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = "finbotaiagent-service"
}

variable "codebuild_compute_type" {
  description = "CodeBuild compute type for build project"
  type        = string
  default     = "BUILD_GENERAL1_MEDIUM"
  
  validation {
    condition = contains([
      "BUILD_GENERAL1_SMALL",
      "BUILD_GENERAL1_MEDIUM",
      "BUILD_GENERAL1_LARGE",
      "BUILD_GENERAL1_2XLARGE"
    ], var.codebuild_compute_type)
    error_message = "CodeBuild compute type must be one of the valid BUILD_GENERAL1 types."
  }
}

variable "codebuild_test_compute_type" {
  description = "CodeBuild compute type for test project"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
  
  validation {
    condition = contains([
      "BUILD_GENERAL1_SMALL",
      "BUILD_GENERAL1_MEDIUM",
      "BUILD_GENERAL1_LARGE",
      "BUILD_GENERAL1_2XLARGE"
    ], var.codebuild_test_compute_type)
    error_message = "CodeBuild test compute type must be one of the valid BUILD_GENERAL1 types."
  }
}

variable "enable_manual_approval" {
  description = "Enable manual approval step before deployment"
  type        = bool
  default     = true
}

variable "approval_sns_topic_arn" {
  description = "SNS topic ARN for manual approval notifications"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID for CodeBuild projects (optional)"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnet IDs for CodeBuild projects (optional)"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security group IDs for CodeBuild projects (optional)"
  type        = list(string)
  default     = []
}

variable "enable_vpc" {
  description = "Enable VPC configuration for CodeBuild projects"
  type        = bool
  default     = false
}

variable "build_timeout" {
  description = "Build timeout in minutes"
  type        = number
  default     = 60
  
  validation {
    condition     = var.build_timeout >= 5 && var.build_timeout <= 480
    error_message = "Build timeout must be between 5 and 480 minutes."
  }
}

variable "test_timeout" {
  description = "Test timeout in minutes"
  type        = number
  default     = 30
  
  validation {
    condition     = var.test_timeout >= 5 && var.test_timeout <= 480
    error_message = "Test timeout must be between 5 and 480 minutes."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_ecr_scanning" {
  description = "Enable ECR image scanning"
  type        = bool
  default     = true
}

variable "ecr_image_retention_count" {
  description = "Number of images to retain in ECR"
  type        = number
  default     = 10
  
  validation {
    condition     = var.ecr_image_retention_count >= 1 && var.ecr_image_retention_count <= 100
    error_message = "ECR image retention count must be between 1 and 100."
  }
}

variable "artifacts_retention_days" {
  description = "Number of days to retain pipeline artifacts"
  type        = number
  default     = 30
  
  validation {
    condition     = var.artifacts_retention_days >= 1 && var.artifacts_retention_days <= 365
    error_message = "Artifacts retention days must be between 1 and 365."
  }
}
