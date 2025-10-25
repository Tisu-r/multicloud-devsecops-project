# terraform/gcp/variables.tf

variable "gcp_project_id" {
  type        = string
  description = "The GCP project ID."
}

variable "gcp_region" {
  type        = string
  description = "The GCP region for resources."
  default     = "us-central1"
}

# service_name -> job_name 으로 변경
variable "job_name" {
  type        = string
  description = "The name of the Cloud Run Job."
  default     = "log-generator-job"
}

# container_image -> image_url 로 변경 (GitHub Actions 워크플로우와 일치)
variable "image_url" {
  type        = string
  description = "The container image URL for the Cloud Run Job."
  # 기본값은 비워두거나 테스트용 이미지를 넣습니다. 이 값은 CI/CD 파이프라인에서 덮어쓰게 됩니다.
  default     = "us-docker.pkg.dev/cloudrun/container/hello" 
}

# 새로 추가된 변수
variable "job_schedule" {
  type        = string
  description = "The cron schedule for the Cloud Scheduler job (e.g., '*/10 * * * *' for every 10 minutes)."
  default     = "*/10 * * * *"
}