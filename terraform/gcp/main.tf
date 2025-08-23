# terraform/gcp/main.tf

# 1. 필요한 GCP API들을 자동으로 활성화합니다.
# ----------------------------------------------------
resource "google_project_service" "cloudrun_api" {
  project = var.gcp_project_id
  service = "run.googleapis.com"
  disable_on_destroy = false # 테라폼으로 삭제해도 API는 끄지 않음
}

resource "google_project_service" "iam_api" {
  project = var.gcp_project_id
  service = "iam.googleapis.com"
  disable_on_destroy = false
}

# 2. Cloud Run 서비스를 생성합니다.
# ----------------------------------------------------
resource "google_cloud_run_v2_service" "default" {
  project  = var.gcp_project_id
  name     = var.service_name
  location = var.gcp_region

  # API가 활성화된 후에 이 리소스를 만들도록 순서를 지정합니다.
  depends_on = [google_project_service.cloudrun_api]

  template {
    containers {
      image = var.container_image # 배포할 컨테이너 이미지를 변수로 받습니다.
    }
  }
}

# 3. 생성된 Cloud Run 서비스를 외부에서 접속할 수 있도록 공개 설정합니다.
# ----------------------------------------------------
resource "google_cloud_run_v2_service_iam_binding" "allow_public" {
  project  = google_cloud_run_v2_service.default.project
  location = google_cloud_run_v2_service.default.location
  name     = google_cloud_run_v2_service.default.name
  
  role    = "roles/run.invoker" # 'run.invoker'는 서비스를 호출할 수 있는 권한입니다.
  members = ["allUsers"]        # 'allUsers'는 인증 없이 누구나 호출할 수 있음을 의미합니다.

  depends_on = [google_project_service.iam_api]
}