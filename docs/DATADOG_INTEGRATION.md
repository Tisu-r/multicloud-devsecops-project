# Datadog GCP 통합 가이드

이 문서는 GCP 구독형 Datadog을 사용하여 log-generator-job의 로그를 수집하고 모니터링하는 방법을 설명합니다.

## 📋 목차
1. [개요](#개요)
2. [GCP Datadog 통합 설정](#gcp-datadog-통합-설정)
3. [로그 수집 구성](#로그-수집-구성)
4. [메트릭 수집](#메트릭-수집)
5. [대시보드 및 알림](#대시보드-및-알림)
6. [트러블슈팅](#트러블슈팅)

---

## 개요

### 아키텍처
```
Cloud Run Job → Cloud Logging → Datadog Log Forwarder → Datadog
                                        ↓
                                  Log Pipeline
                                  (파싱/필터링)
                                        ↓
                                  Datadog Logs
```

### 프로젝트 정보
| 항목 | 값 |
|------|-----|
| **GCP 프로젝트 ID** | `main-ember-469911-e9` |
| **GCP 프로젝트 번호** | `1082524335295` |
| **리전** | `us-central1` |
| **Cloud Run Job** | `log-generator-job` |
| **환경** | `dev` |

### 로그 형식
```json
{
  "timestamp": "2025-10-26T09:59:00.656198Z",
  "level": "INFO|WARN|ERROR|CRITICAL",
  "service": "api-gateway|user-service|product-service|order-service|auth-service",
  "event_type": "api_call|order_processed|payment_failed|login_failed|permission_denied|suspicious_activity",
  "message": "로그 메시지",
  "details": {
    // 이벤트 타입별 상세 정보
  }
}
```

---

## GCP Datadog 통합 설정

### 1. Datadog GCP Integration 활성화

GCP Marketplace에서 Datadog을 구독한 경우:

1. **Datadog Console 접속**
   - GCP Console → Datadog 리소스로 이동
   - Datadog 포털 URL 확인

2. **GCP Integration 활성화**
   ```
   Datadog Console → Integrations → Google Cloud Platform
   ```

3. **Service Account 생성 및 권한 부여**

   Datadog이 GCP 리소스를 모니터링하려면 Service Account가 필요합니다:

   ```bash
   # Service Account 생성
   gcloud iam service-accounts create datadog-integration \
     --display-name="Datadog Integration Service Account" \
     --project=main-ember-469911-e9
     
   gcloud projects add-iam-policy-binding main-ember-469911-e9 \
     --member="serviceAccount:datadog-integration@main-ember-469911-e9.iam.gserviceaccount.com" \
     --role="roles/compute.viewer"

   gcloud projects add-iam-policy-binding main-ember-469911-e9 \
     --member="serviceAccount:datadog-integration@main-ember-469911-e9.iam.gserviceaccount.com" \
     --role="roles/monitoring.viewer"

   gcloud projects add-iam-policy-binding main-ember-469911-e9 \
     --member="serviceAccount:datadog-integration@main-ember-469911-e9.iam.gserviceaccount.com" \
     --role="roles/logging.viewer"
   ```

4. **Service Account Key 생성**

   ```bash
   gcloud iam service-accounts keys create ~/datadog-sa-key.json \
     --iam-account=datadog-integration@main-ember-469911-e9.iam.gserviceaccount.com \
     --project=main-ember-469911-e9
   ```

5. **Datadog에 Key 업로드**
   - Datadog Console → Integrations → GCP
   - "Add GCP Account" 클릭
   - Service Account JSON 파일 업로드
   - 프로젝트 ID 입력: `main-ember-469911-e9`

---

## 로그 수집 구성

### 방법 1: Cloud Logging to Datadog (권장)

GCP Cloud Logging의 로그를 Datadog으로 전송하는 방법입니다.

#### A. Pub/Sub 기반 Log Sink 설정

1. **Datadog Log Forwarder 배포**

   ```bash
   # Cloud Function 또는 Cloud Run으로 Datadog Log Forwarder 배포
   # Datadog이 제공하는 공식 forwarder 사용

   # 1. Datadog Forwarder 다운로드
   git clone https://github.com/DataDog/datadog-serverless-functions.git
   cd datadog-serverless-functions/gcp/logs_streaming
   ```

2. **환경 변수 설정**

   Cloud Function 배포 시 필요한 환경 변수:
   ```bash
   DD_API_KEY=<YOUR_DATADOG_API_KEY>
   DD_SITE=us5.datadoghq.com  # GCP Datadog는 us5 사이트 사용
   ```

3. **Pub/Sub Topic 생성 (로그 수집용)**

   ```bash
   gcloud pubsub topics create datadog-logs \
     --project=main-ember-469911-e9
   ```

4. **Log Sink 생성**

   Cloud Run Job의 로그만 전송하도록 필터링:

   ```bash
   gcloud logging sinks create datadog-log-sink \
     pubsub.googleapis.com/projects/main-ember-469911-e9/topics/datadog-logs \
     --log-filter='resource.type="cloud_run_job"
   resource.labels.job_name="log-generator-job"
   resource.labels.location="us-central1"' \
     --project=main-ember-469911-e9
   ```

5. **Pub/Sub Publisher 권한 부여**

   ```bash
   # Log Sink의 Service Account 확인
   SINK_SA=$(gcloud logging sinks describe datadog-log-sink \
     --project=main-ember-469911-e9 \
     --format='value(writerIdentity)')

   # Pub/Sub Publisher 권한 부여
   gcloud pubsub topics add-iam-policy-binding datadog-logs \
     --member="$SINK_SA" \
     --role="roles/pubsub.publisher" \
     --project=main-ember-469911-e9
   ```

6. **Cloud Function 배포**

   ```bash
   gcloud functions deploy datadog-log-forwarder \
     --runtime=python39 \
     --trigger-topic=datadog-logs \
     --entry-point=forward_logs \
     --set-env-vars DD_API_KEY=<YOUR_API_KEY>,DD_SITE=us5.datadoghq.com \
     --region=us-central1 \
     --project=main-ember-469911-e9
   ```

#### B. 로그 필터 쿼리 예시

특정 로그만 전송하려면:

```bash
# ERROR 레벨 로그만 전송
--log-filter='resource.type="cloud_run_job"
resource.labels.job_name="log-generator-job"
jsonPayload.level="ERROR"'

# 비즈니스 로그만 전송
--log-filter='resource.type="cloud_run_job"
resource.labels.job_name="log-generator-job"
jsonPayload.event_type="order_processed" OR jsonPayload.event_type="payment_failed"'

# 보안 이벤트만 전송
--log-filter='resource.type="cloud_run_job"
resource.labels.job_name="log-generator-job"
jsonPayload.service="auth-service"'
```

### 방법 2: Direct API Push (고급)

애플리케이션 코드에서 직접 Datadog Logs API로 전송:

```python
# log_generator.py에 추가
import requests
import os

DD_API_KEY = os.environ.get('DD_API_KEY')
DD_SITE = os.environ.get('DD_SITE', 'us5.datadoghq.com')

def send_to_datadog(log_entry):
    """Datadog Logs API로 로그 전송"""
    url = f"https://http-intake.logs.{DD_SITE}/api/v2/logs"

    headers = {
        "DD-API-KEY": DD_API_KEY,
        "Content-Type": "application/json"
    }

    payload = {
        "ddsource": "cloud-run-job",
        "ddtags": f"env:dev,service:log-generator-job",
        "hostname": "log-generator-job",
        "message": log_entry
    }

    response = requests.post(url, json=payload, headers=headers)
    return response.status_code
```

---

## 메트릭 수집

### Cloud Run Job 메트릭

Datadog GCP Integration이 자동으로 수집하는 메트릭:

- `gcp.run.job.execution.count` - Job 실행 횟수
- `gcp.run.job.execution.duration` - Job 실행 시간
- `gcp.run.job.billable_time` - 과금 시간
- `gcp.run.job.cpu.allocation` - CPU 할당량
- `gcp.run.job.memory.allocation` - 메모리 할당량

### Custom Metrics (선택 사항)

DogStatsD를 사용하여 커스텀 메트릭 전송:

```python
from datadog import initialize, statsd

# Datadog 초기화
initialize(api_key=DD_API_KEY, app_key=DD_APP_KEY)

# 메트릭 전송
statsd.increment('log_generator.logs_generated', value=100)
statsd.histogram('log_generator.execution_time', value=45.2)
```

---

## 대시보드 및 알림

### 1. 로그 Explorer 사용

Datadog Console → Logs → Explorer에서 다음 쿼리 사용:

```
# 모든 로그 보기
source:cloud-run-job service:log-generator-job

# ERROR 레벨 로그만
source:cloud-run-job service:log-generator-job status:error

# 특정 이벤트 타입
source:cloud-run-job @event_type:payment_failed

# 특정 시간대 로그
source:cloud-run-job service:log-generator-job @timestamp:[now-1h TO now]
```

### 2. Log Pipelines 설정

Datadog Console → Logs → Configuration → Pipelines

#### Grok Parser 추가

로그를 파싱하여 구조화:

```
# Grok 규칙 예시
rule %{data:timestamp}.*"level":\s*"%{word:level}".*"service":\s*"%{word:service}".*"event_type":\s*"%{word:event_type}"

# 추출된 필드를 facet으로 설정
- level
- service
- event_type
- details.status_code
- details.user_id
```

### 3. 대시보드 생성

#### 위젯 추가 예시:

1. **로그 카운트 (시계열)**
   - Metric: `count` by `level`
   - 필터: `source:cloud-run-job`

2. **서비스별 로그 분포 (파이 차트)**
   - Metric: `count` by `service`

3. **에러 로그 목록 (로그 스트림)**
   - 필터: `status:error`

4. **Job 실행 횟수 (쿼리 값)**
   - Metric: `gcp.run.job.execution.count`

### 4. 알림(Monitors) 설정

#### 예시 1: ERROR 로그 급증 알림

```
Datadog Console → Monitors → New Monitor → Logs

Query:
  source:cloud-run-job status:error

Alert threshold:
  Alert when > 10 logs in 5 minutes

Message:
  {{#is_alert}}
  🚨 Log Generator Job에서 ERROR 로그가 급증했습니다!
  지난 5분간 {{value}} 개의 에러 발생
  {{/is_alert}}
```

#### 예시 2: Job 실행 실패 알림

```
Monitor Type: Metric Monitor

Metric:
  gcp.run.job.execution.count filtered by status:failed

Alert threshold:
  Alert when > 0 in last 10 minutes
```

#### 예시 3: 보안 이벤트 알림

```
Monitor Type: Logs Monitor

Query:
  source:cloud-run-job @event_type:(login_failed OR suspicious_activity)

Alert threshold:
  Alert when > 5 logs in 10 minutes

Notification:
  - Slack: #security-alerts
  - Email: security-team@company.com
```

---

## 로그 리소스 정보

### Cloud Run Job 로그 위치

```
프로젝트: main-ember-469911-e9
리전: us-central1
리소스 타입: cloud_run_job
Job 이름: log-generator-job
로그 이름: stdout (애플리케이션 로그)
```

### 로그 확인 (GCP Console)

```
GCP Console → Logging → Logs Explorer

쿼리:
resource.type="cloud_run_job"
resource.labels.job_name="log-generator-job"
resource.labels.location="us-central1"
```

### 로그 스키마

#### Access 로그
```json
{
  "timestamp": "2025-10-26T10:00:00.000Z",
  "level": "INFO",
  "service": "api-gateway",
  "event_type": "api_call",
  "message": "Request to /api/users completed",
  "details": {
    "request_id": "uuid",
    "http_method": "GET|POST|PUT|DELETE",
    "path": "/api/path",
    "status_code": 200,
    "response_time_ms": 123,
    "user_id": "user-1234",
    "source_ip": "192.168.1.1"
  }
}
```

#### Business 로그
```json
{
  "timestamp": "2025-10-26T10:00:00.000Z",
  "level": "CRITICAL",
  "service": "order-service",
  "event_type": "order_processed",
  "message": "New order #12345 processed",
  "details": {
    "transaction_id": "uuid",
    "user_id": "user-1234",
    "product_ids": ["prod-001", "prod-002"],
    "total_amount": 99.99,
    "currency": "USD|KRW|EUR",
    "payment_method": "credit_card|paypal|bank_transfer",
    "shipping_country": "US"
  }
}
```

#### Security 로그
```json
{
  "timestamp": "2025-10-26T10:00:00.000Z",
  "level": "ERROR",
  "service": "auth-service",
  "event_type": "login_failed",
  "message": "Security event detected: ...",
  "details": {
    "user_id": "username",
    "source_ip": "192.168.1.1",
    "reason": "invalid_credentials|brute_force_attempt|unauthorized_access",
    "attempt_count": 5
  }
}
```

---

## Datadog Log Facets 설정

로그를 효율적으로 분석하려면 다음 facet을 설정하세요:

```
Datadog Console → Logs → Configuration → Facets

추가할 Facets:
- @level (string)
- @service (string)
- @event_type (string)
- @details.status_code (number)
- @details.http_method (string)
- @details.user_id (string)
- @details.source_ip (string)
- @details.transaction_id (string)
- @details.payment_method (string)
- @details.reason (string)
```

---

## 비용 최적화

### 로그 전송량 최적화

1. **샘플링 적용**
   - INFO 레벨: 10% 샘플링
   - WARN 레벨: 50% 샘플링
   - ERROR 레벨: 100% (전체 수집)

2. **로그 제외 규칙**
   - Health check 로그 제외
   - 중복 로그 제외

3. **로그 아카이브 설정**
   - 30일 이상 로그는 GCS로 아카이브
   - Datadog Logs Archive to GCS 활성화

---

## 트러블슈팅

### 1. 로그가 Datadog에 표시되지 않음

**확인 사항:**
- Cloud Logging에 로그가 생성되고 있는지 확인
- Log Sink가 올바르게 설정되었는지 확인
- Pub/Sub Topic에 메시지가 발행되고 있는지 확인
- Cloud Function의 실행 로그 확인

```bash
# Cloud Logging 확인
gcloud logging read "resource.type=cloud_run_job" \
  --limit=10 \
  --project=main-ember-469911-e9

# Pub/Sub 메시지 확인
gcloud pubsub subscriptions pull datadog-logs-sub \
  --auto-ack \
  --limit=5 \
  --project=main-ember-469911-e9

# Cloud Function 로그 확인
gcloud functions logs read datadog-log-forwarder \
  --region=us-central1 \
  --project=main-ember-469911-e9
```

### 2. Datadog API Key 오류

```bash
# API Key 유효성 확인
curl -X POST "https://http-intake.logs.us5.datadoghq.com/api/v2/logs" \
  -H "DD-API-KEY: <YOUR_API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"message":"test"}'
```

### 3. 로그 파싱 실패

Datadog Log Pipelines에서 Grok Parser 규칙을 확인하고 테스트하세요.

---

## 다음 단계

1. **Snowflake 연동** (향후 계획)
   - Datadog Logs Archive → Snowflake
   - ERROR 레벨 로그를 Snowflake로 자동 전송
   - BI 대시보드 연동 (Looker, Tableau)

2. **APM 통합**
   - Datadog APM 에이전트 추가
   - 분산 트레이싱 활성화

3. **신서틱 모니터링**
   - Cloud Run Job의 Health Check
   - 스케줄러 정상 작동 모니터링

---

## 참고 자료

- [Datadog GCP Integration](https://docs.datadoghq.com/integrations/google_cloud_platform/)
- [Datadog Log Collection from GCP](https://docs.datadoghq.com/logs/guide/collect-google-cloud-logs-with-push/)
- [GCP Cloud Logging](https://cloud.google.com/logging/docs)
- [Datadog Log Pipelines](https://docs.datadoghq.com/logs/log_configuration/pipelines/)

---

**작성일**: 2025-10-26
**작성자**: DevOps Team
**버전**: 1.0
