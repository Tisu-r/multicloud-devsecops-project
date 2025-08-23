# terraform/gcp/variables.tf

variable "gcp_project_id" {
  type        = string
  description = "사용할 GCP 프로젝트의 ID입니다."
}

variable "gcp_region" {
  type        = string
  description = "리소스를 생성할 GCP 리전입니다."
  default     = "us-central1" # 기본값을 설정해두면 편리합니다.
}

variable "service_name" {
  type        = string
  description = "Cloud Run 서비스의 이름입니다."
  default     = "my-devsecops-service"
}

variable "container_image" {
  type        = string
  description = "Cloud Run에 배포할 컨테이너 이미지 주소입니다."
  # 이 값은 나중에 GitHub Actions에서 동적으로 전달할 것이므로 기본값이 없습니다.
}