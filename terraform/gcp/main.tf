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

# Pub/Sub API를 활성화합니다.
resource "google_project_service" "pubsub_api" {
  project = var.gcp_project_id
  service = "pubsub.googleapis.com"
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


# 3. Pub/Sub Topic을 생성합니다.
# ----------------------------------------------------
# Cloud Scheduler가 메시지를 발행하고, Cloud Run Job이 구독하는 방식입니다.
resource "google_pubsub_topic" "log_generator_trigger" {
  project = var.gcp_project_id
  name    = "log-generator-trigger-${var.environment}"

  depends_on = [google_project_service.pubsub_api]
}


# 4. Cloud Scheduler가 Pub/Sub에 메시지를 발행할 수 있도록 서비스 계정을 만듭니다.
# ----------------------------------------------------
resource "google_service_account" "scheduler_pubsub_sa" {
  project      = var.gcp_project_id
  account_id   = "scheduler-pubsub-publisher"
  display_name = "Service Account for Scheduler to publish Pub/Sub messages"
}

# Pub/Sub Publisher 권한 부여
resource "google_pubsub_topic_iam_member" "scheduler_publisher" {
  project = var.gcp_project_id
  topic   = google_pubsub_topic.log_generator_trigger.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.scheduler_pubsub_sa.email}"
}


# 5. Cloud Run Job을 실행할 수 있는 서비스 계정을 만듭니다.
# ----------------------------------------------------
resource "google_service_account" "job_runner_sa" {
  project      = var.gcp_project_id
  account_id   = "log-generator-job-runner"
  display_name = "Service Account to run log generator job"
}

# Cloud Run Job 실행 권한 부여
resource "google_cloud_run_v2_job_iam_member" "job_invoker_permission" {
  project  = google_cloud_run_v2_job.log_generator_job.project
  location = google_cloud_run_v2_job.log_generator_job.location
  name     = google_cloud_run_v2_job.log_generator_job.name

  role   = "roles/run.invoker"
  member = "serviceAccount:${google_service_account.job_runner_sa.email}"
}


# 6. Cloud Scheduler를 생성하여 주기적으로 Pub/Sub 메시지를 발행합니다.
# ----------------------------------------------------
resource "google_cloud_scheduler_job" "run_log_generator" {
  project  = var.gcp_project_id
  name     = "run-log-generator-job-${var.environment}"
  region   = var.gcp_region

  # UNIX cron 형식으로 실행 주기를 설정합니다. "*/10 * * * *"는 '10분마다' 라는 뜻입니다.
  schedule  = var.job_schedule
  time_zone = "UTC"

  # Pub/Sub 타겟으로 변경
  pubsub_target {
    topic_name = google_pubsub_topic.log_generator_trigger.id
    data       = base64encode("{\"trigger\":\"scheduled\"}")
  }

  depends_on = [
    google_project_service.scheduler_api,
    google_pubsub_topic.log_generator_trigger,
    google_pubsub_topic_iam_member.scheduler_publisher
  ]
}


# 7. Pub/Sub 구독을 생성하고 Cloud Run Job을 트리거합니다.
# ----------------------------------------------------
resource "google_pubsub_subscription" "log_generator_subscription" {
  project = var.gcp_project_id
  name    = "log-generator-subscription-${var.environment}"
  topic   = google_pubsub_topic.log_generator_trigger.name

  # Push 방식으로 Cloud Run Job 실행
  push_config {
    push_endpoint = "https://${var.gcp_region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.gcp_project_number}/jobs/${var.job_name}:run"

    oidc_token {
      service_account_email = google_service_account.job_runner_sa.email
    }
  }

  ack_deadline_seconds = 600

  depends_on = [
    google_pubsub_topic.log_generator_trigger,
    google_cloud_run_v2_job_iam_member.job_invoker_permission
  ]
}