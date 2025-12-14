# Datadog API 연결 작업 가이드

**작성일**: 2025-10-26
**상태**: 준비 완료 - 작업 대기 중

---

## 📋 현재 상황

### ✅ 완료된 사항
- Cloud Run Job이 10분마다 자동 실행 중
- Datadog API Key 환경 변수 주입 완료 (`DD_API_KEY`, `DD_SITE`)
- `send_to_datadog()` 함수 이미 구현되어 있음 (log_generator.py)
- 로그 100개씩 정상 생성 중 (Cloud Logging에 출력)

### ❌ 아직 안 된 것
- **Datadog으로 로그 전송이 실제로 이루어지지 않음**
- `send_to_datadog()` 함수를 호출하지 않고 있음
- 현재는 `print()`만 하여 Cloud Logging에만 저장됨

---

## 🎯 해야 할 작업

### 옵션 선택하기

총 3가지 방법이 있습니다:

| 방법 | 난이도 | 시간 | 추천 대상 |
|------|--------|------|-----------|
| **방법 1: 직접 전송** | ⭐ 쉬움 | 5분 | 빠른 테스트, 간단한 구현 |
| **방법 2: Log Forwarder** | ⭐⭐⭐ 어려움 | 30분 | 프로덕션, 안정성 중시 |
| **방법 3: 하이브리드** | ⭐⭐ 보통 | 15분 | 실무 환경 권장 |

---

## 방법 1: 애플리케이션에서 직접 전송 (가장 간단)

### 작업 내용

**파일**: `src/log_generator/log_generator.py`

**수정할 부분**: 141-142줄

**변경 전:**
```python
if __name__ == "__main__":
    logs = [generate_log() for _ in range(100)]

    for log in logs:
        print(json.dumps(log))  # Cloud Logging에만 출력
```

**변경 후:**
```python
if __name__ == "__main__":
    logs = [generate_log() for _ in range(100)]

    success_count = 0
    fail_count = 0

    for log in logs:
        # 1. Cloud Logging에 출력 (GCP 콘솔에서 확인용)
        print(json.dumps(log))

        # 2. Datadog으로 전송
        status_code = send_to_datadog(log)
        if status_code == 202:  # Datadog는 202 Accepted 반환
            success_count += 1
        else:
            fail_count += 1

    print(f"📊 Datadog 전송 완료: 성공 {success_count}, 실패 {fail_count}")
```

### 배포 방법

1. 코드 수정 후 저장
2. Git 커밋 & 푸시
   ```bash
   git add src/log_generator/log_generator.py
   git commit -m "feat: Datadog 직접 로그 전송 활성화"
   git push origin main
   ```
3. GitHub Actions가 자동으로 빌드 & 배포 (약 5분 소요)
4. 다음 10분 단위에 자동 실행되면서 Datadog으로 로그 전송 시작

### 확인 방법

**GCP Cloud Logging에서:**
```
📊 Datadog 전송 완료: 성공 100, 실패 0
```
이런 메시지가 보이면 성공!

**Datadog Console에서:**
1. Logs → Explorer 이동
2. 검색: `source:cloud-run-job service:log-generator-job`
3. 로그가 보이면 성공!

### 장점
- 간단함 (코드 10줄 추가)
- 즉시 작동
- 실시간 전송

### 단점
- 네트워크 실패 시 로그 손실 가능
- Job 실행 시간 약간 증가 (100개 전송에 ~5초)

---

## 방법 2: Cloud Logging → Datadog Forwarder (프로덕션 권장)

### 개요
```
Cloud Run Job → Cloud Logging → Log Sink → Pub/Sub → Cloud Function → Datadog
```

### 작업 단계

#### Step 1: Pub/Sub Topic 생성
```bash
gcloud pubsub topics create datadog-logs \
  --project=main-ember-469911-e9
```

#### Step 2: Log Sink 생성

**옵션 A: 모든 로그 전송**
```bash
gcloud logging sinks create datadog-log-sink \
  pubsub.googleapis.com/projects/main-ember-469911-e9/topics/datadog-logs \
  --log-filter='resource.type="cloud_run_job"
  resource.labels.job_name="log-generator-job"' \
  --project=main-ember-469911-e9
```

**옵션 B: ERROR 이상만 전송 (비용 절감)**
```bash
gcloud logging sinks create datadog-log-sink \
  pubsub.googleapis.com/projects/main-ember-469911-e9/topics/datadog-logs \
  --log-filter='resource.type="cloud_run_job"
  resource.labels.job_name="log-generator-job"
  (jsonPayload.level="ERROR" OR jsonPayload.level="CRITICAL" OR jsonPayload.level="CRITICAL_ANOMALY")' \
  --project=main-ember-469911-e9
```

**옵션 C: 샘플링 (10%만 전송)**
```bash
gcloud logging sinks create datadog-log-sink \
  pubsub.googleapis.com/projects/main-ember-469911-e9/topics/datadog-logs \
  --log-filter='resource.type="cloud_run_job"
  resource.labels.job_name="log-generator-job"
  sample(insertId, 0.1)' \
  --project=main-ember-469911-e9
```

#### Step 3: Log Sink 권한 부여
```bash
# Sink의 Service Account 확인
SINK_SA=$(gcloud logging sinks describe datadog-log-sink \
  --project=main-ember-469911-e9 \
  --format='value(writerIdentity)')

echo "Sink Service Account: $SINK_SA"

# Pub/Sub Publisher 권한 부여
gcloud pubsub topics add-iam-policy-binding datadog-logs \
  --member="$SINK_SA" \
  --role="roles/pubsub.publisher" \
  --project=main-ember-469911-e9
```

#### Step 4: Datadog Log Forwarder 배포

**방법 A: Datadog 공식 Forwarder 사용**
```bash
# 1. Forwarder 다운로드
git clone https://github.com/DataDog/datadog-serverless-functions.git
cd datadog-serverless-functions/gcp/logs_streaming

# 2. Cloud Function 배포
gcloud functions deploy datadog-log-forwarder \
  --runtime=python39 \
  --trigger-topic=datadog-logs \
  --entry-point=forward_logs \
  --set-env-vars DD_API_KEY=<YOUR_DATADOG_API_KEY>,DD_SITE=us5.datadoghq.com \
  --region=us-central1 \
  --project=main-ember-469911-e9 \
  --memory=256MB \
  --timeout=60s
```

**방법 B: 커스텀 Forwarder (간단 버전)**

파일 생성: `datadog_forwarder/main.py`
```python
import base64
import json
import os
import requests

DD_API_KEY = os.environ.get('DD_API_KEY')
DD_SITE = os.environ.get('DD_SITE', 'us5.datadoghq.com')

def forward_logs(event, context):
    """Pub/Sub 메시지를 Datadog으로 전달"""

    if 'data' not in event:
        return 'No data in message', 400

    # Pub/Sub 메시지 디코딩
    pubsub_message = base64.b64decode(event['data']).decode('utf-8')
    log_entry = json.loads(pubsub_message)

    # Datadog으로 전송
    url = f"https://http-intake.logs.{DD_SITE}/api/v2/logs"

    headers = {
        "DD-API-KEY": DD_API_KEY,
        "Content-Type": "application/json"
    }

    payload = {
        "ddsource": "cloud-logging",
        "ddtags": "env:dev,service:log-generator-job",
        "message": log_entry
    }

    response = requests.post(url, json=payload, headers=headers)

    if response.status_code == 202:
        return 'OK', 200
    else:
        return f'Failed: {response.status_code}', 500
```

파일 생성: `datadog_forwarder/requirements.txt`
```
requests==2.31.0
```

배포:
```bash
cd datadog_forwarder
gcloud functions deploy datadog-log-forwarder \
  --runtime=python39 \
  --trigger-topic=datadog-logs \
  --entry-point=forward_logs \
  --set-env-vars DD_API_KEY=<YOUR_DATADOG_API_KEY>,DD_SITE=us5.datadoghq.com \
  --region=us-central1 \
  --project=main-ember-469911-e9
```

#### Step 5: 테스트

**로그 확인:**
```bash
# Cloud Function 로그 확인
gcloud functions logs read datadog-log-forwarder \
  --region=us-central1 \
  --project=main-ember-469911-e9 \
  --limit=10
```

**수동 테스트:**
```bash
# Pub/Sub에 테스트 메시지 발행
gcloud pubsub topics publish datadog-logs \
  --message='{"test": "message"}' \
  --project=main-ember-469911-e9
```

### 장점
- 로그 손실 없음 (Cloud Logging에 영구 저장)
- 필터링 & 샘플링 가능 (비용 절감)
- Job 성능에 영향 없음
- 재시도 자동 처리

### 단점
- 설정 복잡
- Cloud Function 추가 비용 (아주 적음)
- 약간의 지연 (수 초)

---

## 방법 3: 하이브리드 (실무 권장)

### 전략
- **중요한 로그**: 애플리케이션에서 직접 전송 (실시간)
- **일반 로그**: Cloud Logging → Forwarder (안정적)

### 구현

**log_generator.py 수정:**
```python
if __name__ == "__main__":
    logs = [generate_log() for _ in range(100)]

    critical_sent = 0

    for log in logs:
        # 1. 항상 Cloud Logging에 출력
        print(json.dumps(log))

        # 2. ERROR 이상만 Datadog 직접 전송
        if log['level'] in ['ERROR', 'CRITICAL', 'CRITICAL_ANOMALY']:
            status_code = send_to_datadog(log)
            if status_code == 202:
                critical_sent += 1

    print(f"📊 중요 로그 {critical_sent}개를 Datadog으로 직접 전송 완료")
    print(f"ℹ️  일반 로그는 Log Forwarder를 통해 전송됩니다")
```

**Log Sink 설정 (INFO 레벨만):**
```bash
gcloud logging sinks create datadog-log-sink \
  pubsub.googleapis.com/projects/main-ember-469911-e9/topics/datadog-logs \
  --log-filter='resource.type="cloud_run_job"
  resource.labels.job_name="log-generator-job"
  jsonPayload.level="INFO"' \
  --project=main-ember-469911-e9
```

### 장점
- 중요한 로그는 실시간
- 일반 로그는 안정적
- 비용 효율적
- 유연함

---

## 🔍 확인 및 모니터링

### Datadog Console에서 로그 확인

1. **Logs Explorer 접속**
   ```
   https://us5.datadoghq.com/logs
   ```

2. **검색 쿼리**
   ```
   # 모든 로그 보기
   source:cloud-run-job service:log-generator-job

   # ERROR만 보기
   source:cloud-run-job service:log-generator-job status:error

   # 특정 이벤트 타입
   source:cloud-run-job @event_type:suspicious_activity

   # 중요 보안 이벤트
   source:cloud-run-job @level:CRITICAL_ANOMALY
   ```

3. **Facet 설정** (로그 분석을 위해)
   - `@level` (string)
   - `@service` (string)
   - `@event_type` (string)
   - `@details.status_code` (number)
   - `@details.attempt_count` (number)
   - `@details.reason` (string)

### GCP에서 상태 확인

**Cloud Run Job 로그:**
```bash
gcloud logging read "resource.type=cloud_run_job
resource.labels.job_name=log-generator-job" \
  --limit=20 \
  --project=main-ember-469911-e9
```

**Log Sink 상태 확인:**
```bash
gcloud logging sinks describe datadog-log-sink \
  --project=main-ember-469911-e9
```

**Pub/Sub 메시지 확인:**
```bash
gcloud pubsub topics list --project=main-ember-469911-e9
gcloud pubsub subscriptions list --project=main-ember-469911-e9
```

**Cloud Function 상태:**
```bash
gcloud functions describe datadog-log-forwarder \
  --region=us-central1 \
  --project=main-ember-469911-e9
```

---

## 💰 비용 예상

### 방법 1: 직접 전송
- Cloud Run: 기존과 동일 (실행 시간 약간 증가)
- Datadog: 로그 수집 비용만
- **월 예상 비용**: ~$5 (100개 로그 × 144회/일 × 30일)

### 방법 2: Log Forwarder
- Cloud Logging: $0.50/GB
- Pub/Sub: $0.06/GB
- Cloud Function: $0.40/백만 호출
- Datadog: 로그 수집 비용
- **월 예상 비용**: ~$8

### 방법 3: 하이브리드
- 중간 수준
- **월 예상 비용**: ~$6

---

## 🐛 트러블슈팅

### 문제 1: Datadog에 로그가 안 보임

**체크리스트:**
```bash
# 1. API Key 확인
echo $DD_API_KEY

# 2. Cloud Run Job 환경 변수 확인
gcloud run jobs describe log-generator-job \
  --region=us-central1 \
  --project=main-ember-469911-e9 \
  --format="value(template.spec.template.spec.containers[0].env)"

# 3. Cloud Function 로그 확인 (방법 2 사용 시)
gcloud functions logs read datadog-log-forwarder \
  --region=us-central1 \
  --project=main-ember-469911-e9

# 4. Datadog API 직접 테스트
curl -X POST "https://http-intake.logs.us5.datadoghq.com/api/v2/logs" \
  -H "DD-API-KEY: <YOUR_DATADOG_API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"message":"test log", "ddsource":"test"}'
```

### 문제 2: 403 Forbidden (Datadog)
- API Key 확인
- DD_SITE 확인 (us5.datadoghq.com이 맞는지)

### 문제 3: Log Sink가 작동 안 함
```bash
# Sink 권한 확인
gcloud logging sinks describe datadog-log-sink \
  --project=main-ember-469911-e9

# Pub/Sub IAM 확인
gcloud pubsub topics get-iam-policy datadog-logs \
  --project=main-ember-469911-e9
```

---

## 📚 참고 자료

- [Datadog GCP Integration 공식 문서](https://docs.datadoghq.com/integrations/google_cloud_platform/)
- [Datadog Log Collection from GCP](https://docs.datadoghq.com/logs/guide/collect-google-cloud-logs-with-push/)
- [Datadog Logs API](https://docs.datadoghq.com/api/latest/logs/)
- [GCP Cloud Logging Sinks](https://cloud.google.com/logging/docs/export/configure_export_v2)
- [프로젝트 Datadog 통합 가이드](./DATADOG_INTEGRATION.md)

---

## ✅ 권장 작업 순서

### 빠른 테스트용 (오늘 바로 시작)
1. **방법 1** 선택
2. log_generator.py 수정 (10줄 추가)
3. Git 푸시
4. 5분 대기
5. Datadog에서 로그 확인

### 프로덕션 준비 (이번 주 내)
1. 방법 1로 테스트 완료 후
2. **방법 3 (하이브리드)** 로 전환
3. Log Forwarder 배포
4. Log Sink 설정
5. 모니터링 대시보드 구축

---

**작성일**: 2025-10-26
**다음 업데이트**: 작업 완료 후
