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

resource "google_project_service" "scheduler_api" {
  project = var.gcp_project_id
  service = "cloudscheduler.googleapis.com"
  disable_on_destroy = false
}

# (추가) GCS API 활성화
resource "google_project_service" "storage_api" {
  project = var.gcp_project_id
  service = "storage.googleapis.com"
  disable_on_destroy = false
}


# 2. GCS 버킷을 생성합니다. (로그 파일 저장소)
# ----------------------------------------------------
resource "google_storage_bucket" "log_data_bucket" {
  project      = var.gcp_project_id
  name         = var.gcs_bucket_name # variables.tf에 정의할 변수 필요
  location     = var.gcp_region
  
  # 테스트 환경 단순화를 위해 force_destroy = true 설정
  force_destroy = true 
  uniform_bucket_level_access = true 

  depends_on = [google_project_service.storage_api]
}


# 3. Cloud Run Job이 GCS에 접근하며 '실제로 실행'할 전용 서비스 계정을 만듭니다. (Executor SA)
# ----------------------------------------------------
resource "google_service_account" "job_executor_sa" {
  project      = var.gcp_project_id
  account_id   = "cloudrun-job-executor"
  display_name = "Service Account to execute Cloud Run Jobs and access GCS"
}


# 4. Job 실행 계정에 GCS 버킷에 파일을 올릴 권한을 부여합니다.
# ----------------------------------------------------
resource "google_storage_bucket_iam_member" "log_bucket_iam_binding" {
  bucket = google_storage_bucket.log_data_bucket.name
  role   = "roles/storage.objectAdmin" # 파일을 읽고, 쓰고, 삭제할 수 있는 권한
  member = "serviceAccount:${google_service_account.job_executor_sa.email}"

  depends_on = [google_storage_bucket.log_data_bucket, google_service_account.job_executor_sa]
}


# 5. Cloud Run Job을 생성합니다. (Job 실행 계정 및 환경 변수 주입)
# ----------------------------------------------------
# 이것이 바로 로그를 생성하는 컨테이너를 실행할 '일회성 작업'입니다.
resource "google_cloud_run_v2_job" "log_generator_job" {
  project  = var.gcp_project_id
  name     = var.job_name
  location = var.gcp_region

  depends_on = [
    google_project_service.cloudrun_api,
    google_storage_bucket.log_data_bucket,
    google_service_account.job_executor_sa # Job보다 SA가 먼저 정의되어야 함
  ]

  template {
    template {
      # 5-1. (핵심) Job 실행 계정을 지정합니다. (GCS 접근 권한을 가진 계정)
      service_account = google_service_account.job_executor_sa.email 
      
      containers {
        image = var.image_url 
        
        # 5-2. (핵심) Python 스크립트가 사용할 BUCKET_NAME 환경 변수 주입
        env {
          name  = "BUCKET_NAME"
          value = google_storage_bucket.log_data_bucket.name
        }
      }
    }
  }
}


# 6. Cloud Scheduler가 Cloud Run Job을 실행할 수 있도록 전용 서비스 계정을 만듭니다.
# ----------------------------------------------------
# 보안을 위해 스케줄러만을 위한 최소한의 권한을 가진 계정을 만드는 것이 좋습니다.
resource "google_service_account" "scheduler_invoker_sa" {
  project      = var.gcp_project_id
  account_id   = "scheduler-job-invoker"
  display_name = "Service Account to invoke Cloud Run Jobs"
}


# 7. 위에서 만든 서비스 계정에게 Cloud Run Job을 '실행(invoke)'할 권한을 부여합니다.
# ----------------------------------------------------
# 공개적으로 열어두는 'allUsers' 대신, 지정된 서비스 계정에게만 권한을 줍니다. (훨씬 안전함)
resource "google_cloud_run_v2_job_iam_member" "job_invoker_permission" {
  project  = google_cloud_run_v2_job.log_generator_job.project
  location = google_cloud_run_v2_job.log_generator_job.location
  name     = google_cloud_run_v2_job.log_generator_job.name
  
  role   = "roles/run.invoker" # 'run.invoker'는 작업을 호출할 수 있는 권한입니다.
  member = "serviceAccount:${google_service_account.scheduler_invoker_sa.email}"
  
  depends_on = [google_cloud_run_v2_job.log_generator_job]
}


# 8. Cloud Scheduler를 생성하여 주기적으로 Cloud Run Job을 실행시킵니다.
# ----------------------------------------------------
resource "google_cloud_scheduler_job" "run_log_generator" {
  project  = var.gcp_project_id
  name     = "run-log-generator-job-${var.environment}"
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