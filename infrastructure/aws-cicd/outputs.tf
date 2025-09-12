# Outputs for FinBotAiAgent CI/CD infrastructure

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.main.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.main.arn
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.main.name
}

output "pipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.main.name
}

output "pipeline_arn" {
  description = "ARN of the CodePipeline"
  value       = aws_codepipeline.main.arn
}

output "pipeline_url" {
  description = "URL to view the pipeline in AWS Console"
  value       = "https://${var.aws_region}.console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipeline.main.name}/view"
}

output "build_project_name" {
  description = "Name of the CodeBuild build project"
  value       = aws_codebuild_project.build.name
}

output "build_project_arn" {
  description = "ARN of the CodeBuild build project"
  value       = aws_codebuild_project.build.arn
}

output "test_project_name" {
  description = "Name of the CodeBuild test project"
  value       = aws_codebuild_project.test.name
}

output "test_project_arn" {
  description = "ARN of the CodeBuild test project"
  value       = aws_codebuild_project.test.arn
}

output "artifacts_bucket_name" {
  description = "Name of the S3 bucket for artifacts"
  value       = aws_s3_bucket.artifacts.bucket
}

output "artifacts_bucket_arn" {
  description = "ARN of the S3 bucket for artifacts"
  value       = aws_s3_bucket.artifacts.arn
}

output "artifacts_bucket_domain_name" {
  description = "Domain name of the S3 bucket for artifacts"
  value       = aws_s3_bucket.artifacts.bucket_domain_name
}

output "codebuild_service_role_arn" {
  description = "ARN of the CodeBuild service role"
  value       = aws_iam_role.codebuild_role.arn
}

output "codepipeline_service_role_arn" {
  description = "ARN of the CodePipeline service role"
  value       = aws_iam_role.codepipeline_role.arn
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log groups created for the pipeline"
  value = {
    build_logs = "/aws/codebuild/${aws_codebuild_project.build.name}"
    test_logs  = "/aws/codebuild/${aws_codebuild_project.test.name}"
  }
}

output "next_steps" {
  description = "Next steps to complete the setup"
  value = <<-EOT
    1. Create ECS cluster: aws ecs create-cluster --cluster-name ${var.project_name}-cluster
    2. Create ECS service using the task definition template
    3. Configure secrets in Parameter Store and Secrets Manager
    4. Push code to trigger the pipeline
    5. Monitor the pipeline in AWS Console: ${self.pipeline_url}
  EOT
}

output "docker_login_command" {
  description = "Command to login to ECR for local Docker builds"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.main.repository_url}"
}

output "deployment_commands" {
  description = "Useful deployment commands"
  value = {
    manual_deploy = "./aws-cicd/deploy-ecs.sh -c ${var.project_name}-cluster -s ${var.project_name}-service"
    check_status  = "aws codepipeline get-pipeline-state --name ${aws_codepipeline.main.name} --region ${var.aws_region}"
    view_logs     = "aws logs tail /aws/codebuild/${aws_codebuild_project.build.name} --follow"
  }
}
