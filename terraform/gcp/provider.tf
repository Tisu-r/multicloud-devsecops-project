# terraform/gcp/provider.tf

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.50" # 특정 버전의 GCP 플러그인을 사용하도록 고정
    }
  }
}

# GCP 프로바이더 설정
provider "google" {
  project = var.gcp_project_id # 프로젝트 ID는 변수로 받음
  region  = var.gcp_region     # 지역(리전)도 변수로 받음
}