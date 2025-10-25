# terraform/gcp/main.tf

# 1. 필요한 GCP API들을 자동으로 활성화합니다.
# ----------------------------------------------------
resource "google_project_service" "cloudrun_api" {
  project = var.gcp_project_id
  service = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iam_api" {
  project = var.gcp_project_id
  service = "iam.googleapis.com"
  disable_on_destroy = false
}

# Cloud Scheduler API를 추가로 활성화합니다.
resource "google_project_service" "scheduler_api" {
  project = var.gcp_project_id
  service = "cloudscheduler.googleapis.com"
  disable_on_destroy = false
}


# 2. Cloud Run Job을 생성합니다. (기존 Service에서 변경)
# ----------------------------------------------------
# 이것이 바로 로그를 생성하는 컨테이너를 실행할 '일회성 작업'입니다.
resource "google_cloud_run_v2_job" "log_generator_job" {
  project  = var.gcp_project_id
  name     = var.job_name # 변수명 변경 (service_name -> job_name)
  location = var.gcp_region

  depends_on = [google_project_service.cloudrun_api]

  template {
    template {
      containers {
        image = var.image_url # GitHub Actions에서 이 값을 동적으로 전달해줍니다.
      }
    }
  }
}


# 3. Cloud Scheduler가 Cloud Run Job을 실행할 수 있도록 전용 서비스 계정을 만듭니다.
# ----------------------------------------------------
# 보안을 위해 스케줄러만을 위한 최소한의 권한을 가진 계정을 만드는 것이 좋습니다.
resource "google_service_account" "scheduler_invoker_sa" {
  project      = var.gcp_project_id
  account_id   = "scheduler-job-invoker"
  display_name = "Service Account to invoke Cloud Run Jobs"
}


# 4. 위에서 만든 서비스 계정에게 Cloud Run Job을 '실행(invoke)'할 권한을 부여합니다.
# ----------------------------------------------------
# 공개적으로 열어두는 'allUsers' 대신, 지정된 서비스 계정에게만 권한을 줍니다. (훨씬 안전함)
resource "google_cloud_run_v2_job_iam_member" "job_invoker_permission" {
  project  = google_cloud_run_v2_job.log_generator_job.project
  location = google_cloud_run_v2_job.log_generator_job.location
  name     = google_cloud_run_v2_job.log_generator_job.name
  
  role   = "roles/run.invoker" # 'run.invoker'는 작업을 호출할 수 있는 권한입니다.
  member = "serviceAccount:${google_service_account.scheduler_invoker_sa.email}"
}


# 5. Cloud Scheduler를 생성하여 주기적으로 Cloud Run Job을 실행시킵니다.
# ----------------------------------------------------
resource "google_cloud_scheduler_job" "run_log_generator" {
  project  = var.gcp_project_id
  name     = "run-log-generator-job"
  region = var.gcp_region
  
  # UNIX cron 형식으로 실행 주기를 설정합니다. "*/10 * * * *"는 '10분마다' 라는 뜻입니다.
  schedule = var.job_schedule

  # 호출할 대상(Target)을 지정합니다.
  http_target {
    # Cloud Run Job을 실행하는 공식 API 엔드포인트 URL입니다.
    uri = "https://run.googleapis.com/v1/${google_cloud_run_v2_job.log_generator_job.id}:run"
    http_method = "POST"
    
    # 인증 방식: 위에서 만든 서비스 계정의 권한을 사용하여 인증합니다.
    oidc_token {
      service_account_email = google_service_account.scheduler_invoker_sa.email
    }
  }

  depends_on = [
    google_project_service.scheduler_api,
    google_cloud_run_v2_job_iam_member.job_invoker_permission
  ]
}