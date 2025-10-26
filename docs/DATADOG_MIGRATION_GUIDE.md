# Datadog 계정 마이그레이션 가이드

> 체험판 계정에서 정식 계정으로 Datadog을 변경할 때 필요한 작업 가이드입니다.

## 📋 목차
1. [마이그레이션 개요](#마이그레이션-개요)
2. [사전 준비](#사전-준비)
3. [마이그레이션 절차](#마이그레이션-절차)
4. [검증 방법](#검증-방법)
5. [롤백 방법](#롤백-방법)

---

## 마이그레이션 개요

### 변경이 필요한 항목

| 항목 | 현재 값 (체험판) | 변경 필요 여부 |
|------|------------------|----------------|
| **Datadog API Key** | `51d1b347e7d2687eb0e467f8f9bf8c6e` | ✅ 필수 |
| **Datadog Site** | `us5.datadoghq.com` | ⚠️ 계정마다 다름 |
| **Service Account** | `ddgci-d88faed1b2e964bca68f@...` | ⚠️ GCP Integration 사용 시 |
| **코드** | `log_generator.py` | ❌ 변경 불필요 |
| **인프라** | Cloud Run, Scheduler 등 | ❌ 변경 불필요 |

### 예상 소요 시간
- **총 소요 시간**: 약 10분
- **다운타임**: 최대 2일 (다음 스케줄 실행까지)
  - 현재 스케줄: 2일마다 실행
  - 최악의 경우: 마이그레이션 직후 스케줄 실행 누락 1회

---

## 사전 준비

### 1. 새 Datadog 계정에서 API Key 발급

1. 새 Datadog 계정 로그인
2. **좌측 메뉴 → Organization Settings → API Keys** 이동
3. **New Key** 클릭
4. Key 이름 입력 (예: `gcp-log-generator-prod`)
5. **Create Key** 클릭 후 API Key 복사

### 2. Datadog Site URL 확인

API Keys 페이지 상단에 표시된 Site URL 확인:
- `https://app.datadoghq.com` → Site: `datadoghq.com`
- `https://us3.datadoghq.com` → Site: `us3.datadoghq.com`
- `https://us5.datadoghq.com` → Site: `us5.datadoghq.com`
- `https://eu1.datadoghq.com` → Site: `datadoghq.eu`

### 3. 백업 (선택 사항)

현재 설정 백업:
```bash
# GitHub Secret 값 기록 (GitHub UI에서 확인 불가하므로 기억해두기)
# 현재 API Key: 51d1b347e7d2687eb0e467f8f9bf8c6e

# 현재 설정 파일 백업
git checkout -b backup/datadog-trial-config
git push origin backup/datadog-trial-config
git checkout main
```

---

## 마이그레이션 절차

### 방법 1: 직접 전송 방식 (현재 사용 중)

#### Step 1: GitHub Secret 업데이트

1. GitHub 저장소 이동: `https://github.com/Tisu-r/multicloud-devsecops-project`
2. **Settings → Secrets and variables → Actions** 클릭
3. `DD_API_KEY` 찾아서 **Update** 클릭
4. 새 API Key 입력 후 **Update secret** 클릭

#### Step 2: Terraform 변수 업데이트 (Site가 다른 경우만)

Site가 `us5.datadoghq.com`이 아니라면:

```bash
# terraform/gcp/main.tf 파일 수정
# 라인 55-56 부근
```

[terraform/gcp/main.tf:55-56](terraform/gcp/main.tf#L55-L56) 수정:
```hcl
env {
  name  = "DD_SITE"
  value = "새로운사이트주소"  # 예: "datadoghq.com", "us3.datadoghq.com"
}
```

저장 후:
```bash
git add terraform/gcp/main.tf
git commit -m "chore: Update Datadog site for new account"
git push origin main
```

#### Step 3: 자동 배포 대기

GitHub Actions가 자동으로:
1. 새 Docker 이미지 빌드
2. Terraform으로 Cloud Run Job 업데이트
3. 새 API Key와 Site로 환경변수 주입

**배포 확인:**
```bash
# GitHub Actions 워크플로우 확인
gh run list --limit 5

# 배포 완료 후 Cloud Run Job 환경변수 확인
gcloud run jobs describe log-generator-job --region=us-central1 --format="value(spec.template.spec.containers[0].env)"
```

---

### 방법 2: Dataflow 사용 시 (추가 작업)

Dataflow를 사용하고 있다면 Secret Manager도 업데이트:

#### Step 1: Secret Manager 업데이트

```bash
# 새 API Key를 Secret Manager에 추가
echo -n "새로운API키" | gcloud secrets versions add datadog-api-key \
  --project=main-ember-469911-e9 \
  --data-file=-
```

#### Step 2: Dataflow Job 재시작

Dataflow는 Secret의 최신 버전을 자동으로 사용하지 않으므로 재시작 필요:

```bash
# 1. 현재 실행 중인 Job 확인
gcloud dataflow jobs list --region=us-central1 --status=active

# 2. Job 취소
gcloud dataflow jobs cancel <JOB_ID> --region=us-central1

# 3. 새 Job 생성 (Secret Manager 방식)
gcloud dataflow flex-template run "datadog-logging-new" \
  --project=main-ember-469911-e9 \
  --region=us-central1 \
  --template-file-gcs-location=gs://dataflow-templates-us-central1/latest/flex/Cloud_PubSub_to_Datadog \
  --parameters \
inputSubscription=projects/main-ember-469911-e9/subscriptions/datadog-log-sub,\
apiKeySource=SECRET_MANAGER,\
apiKeySecret=projects/main-ember-469911-e9/secrets/datadog-api-key/versions/latest,\
url=https://http-intake.logs.새로운사이트주소/api/v2/logs
```

**참고:** `url`의 사이트 주소도 변경 필요 (예: `us5.datadoghq.com` → `datadoghq.com`)

---

### 방법 3: GCP Integration 사용 시

#### Step 1: 기존 Integration 제거

1. 구 Datadog 계정 로그인
2. **Integrations → Google Cloud Platform** 이동
3. 기존 프로젝트 `main-ember-469911-e9` 제거

#### Step 2: GCP에서 기존 SA 권한 제거

```bash
# 기존 Datadog SA 확인
gcloud projects get-iam-policy main-ember-469911-e9 \
  --flatten="bindings[].members" \
  --filter="bindings.members:datadog" \
  --format="table(bindings.members)"

# 권한 제거
gcloud projects remove-iam-policy-binding main-ember-469911-e9 \
  --member="serviceAccount:ddgci-d88faed1b2e964bca68f@datadog-gci-sts-us5-prod.iam.gserviceaccount.com" \
  --role="roles/compute.viewer"

gcloud projects remove-iam-policy-binding main-ember-469911-e9 \
  --member="serviceAccount:ddgci-d88faed1b2e964bca68f@datadog-gci-sts-us5-prod.iam.gserviceaccount.com" \
  --role="roles/monitoring.viewer"
```

#### Step 3: 새 Integration 설정

1. 새 Datadog 계정 로그인
2. **Integrations → Google Cloud Platform** 이동
3. **Add GCP Project** 클릭
4. 프로젝트 ID 입력: `main-ember-469911-e9`
5. 자동 생성된 Service Account에 권한 부여 (Datadog UI에 표시된 명령어 실행)

---

## 검증 방법

### 1. Cloud Run Job 실행 확인

수동으로 Job 실행해서 테스트:

```bash
# 수동 실행
gcloud run jobs execute log-generator-job --region=us-central1

# 실행 로그 확인
gcloud run jobs executions list --job=log-generator-job --region=us-central1 --limit=1

# 상세 로그 확인
gcloud logging read "resource.type=cloud_run_job AND resource.labels.job_name=log-generator-job" \
  --limit=20 \
  --format=json \
  --freshness=10m
```

**성공 시 로그 예시:**
```json
{
  "textPayload": "📊 Datadog 전송 완료: 성공 100, 실패 0"
}
```

### 2. Datadog에서 로그 확인

1. 새 Datadog 계정 로그인
2. **Logs → Search** 이동 (`https://새로운사이트주소/logs`)
3. 검색 쿼리 입력:
   ```
   env:dev service:log-generator
   ```
4. 시간 범위: **Past 15 minutes**
5. 로그 100개 확인

**확인할 필드:**
- `ddsource`: `gcp`
- `service`: `log-generator`
- `env`: `dev`
- `level`: `info`, `warning`, `error`, `CRITICAL_ANOMALY`

### 3. 스케줄 실행 확인

2일 후 자동 실행 확인:

```bash
# 스케줄러 상태 확인
gcloud scheduler jobs describe run-log-generator-job-dev --location=us-central1

# 마지막 실행 시간 확인
gcloud scheduler jobs describe run-log-generator-job-dev \
  --location=us-central1 \
  --format="value(status.lastAttemptTime)"
```

---

## 롤백 방법

마이그레이션 후 문제 발생 시:

### 1. GitHub Secret 복원

1. GitHub → **Settings → Secrets and variables → Actions**
2. `DD_API_KEY` 업데이트
3. 구 API Key 재입력: `51d1b347e7d2687eb0e467f8f9bf8c6e`

### 2. Terraform 변수 복원 (변경한 경우)

```bash
git revert HEAD  # 마지막 커밋 되돌리기
git push origin main
```

### 3. 배포 대기

GitHub Actions가 자동으로 이전 설정으로 복원합니다.

---

## 다운타임 최소화 전략

### 권장 타이밍

체험판 만료 **2-3일 전**에 마이그레이션:
1. 구 계정이 아직 작동 중
2. 새 계정으로 전환
3. 검증 완료 후 구 계정 만료되어도 무중단

### 동시 운영 방식 (고급)

잠시 두 계정 모두 사용:

1. 새 API Key를 추가 환경변수로 주입
2. 코드에서 두 API Key로 동시 전송
3. 새 계정 검증 완료 후 구 계정 제거

**[src/log_generator/log_generator.py](src/log_generator/log_generator.py) 수정 예시:**
```python
# 임시로 두 API Key 모두 사용
DD_API_KEY_OLD = os.environ.get("DD_API_KEY_OLD")
DD_API_KEY_NEW = os.environ.get("DD_API_KEY_NEW")

# 두 계정 모두 전송
send_to_datadog(log, api_key=DD_API_KEY_OLD)
send_to_datadog(log, api_key=DD_API_KEY_NEW)
```

---

## 트러블슈팅

### 문제 1: 로그가 Datadog에 안 보임

**원인:**
- API Key 오타
- Site URL 불일치
- 네트워크 오류

**해결:**
```bash
# Cloud Run Job 환경변수 확인
gcloud run jobs describe log-generator-job --region=us-central1 \
  --format="yaml(spec.template.spec.containers[0].env)"

# 수동 실행하여 에러 로그 확인
gcloud run jobs execute log-generator-job --region=us-central1 --wait
```

### 문제 2: GitHub Actions 배포 실패

**원인:**
- Terraform 권한 부족
- WIF 인증 오류

**해결:**
```bash
# GitHub Actions 로그 확인
gh run list --limit 1
gh run view <RUN_ID> --log-failed

# 수동으로 Terraform 실행
cd terraform/gcp
terraform init
terraform plan
terraform apply
```

### 문제 3: 402 Payment Required 에러

**원인:**
- 새 계정 결제 정보 미등록
- 구독 플랜 문제

**해결:**
1. Datadog → **Organization Settings → Billing** 확인
2. 결제 정보 등록
3. 적절한 플랜 선택

---

## 체크리스트

마이그레이션 완료 후 확인:

- [ ] 새 Datadog 계정에서 API Key 발급 완료
- [ ] GitHub Secret `DD_API_KEY` 업데이트 완료
- [ ] (필요시) `DD_SITE` 환경변수 변경 완료
- [ ] GitHub Actions 배포 성공 확인
- [ ] Cloud Run Job 수동 실행 테스트 성공
- [ ] Datadog에서 로그 100개 확인 완료
- [ ] (Dataflow 사용 시) Secret Manager 업데이트 완료
- [ ] (Dataflow 사용 시) Dataflow Job 재시작 완료
- [ ] (GCP Integration 사용 시) 기존 SA 권한 제거 완료
- [ ] (GCP Integration 사용 시) 새 Integration 설정 완료
- [ ] 2일 후 자동 스케줄 실행 확인 완료

---

## 참고 문서

- [Datadog API Keys 관리](https://docs.datadoghq.com/account_management/api-app-keys/)
- [Datadog Sites 목록](https://docs.datadoghq.com/getting_started/site/)
- [GCP Secret Manager 가이드](https://cloud.google.com/secret-manager/docs)
- [프로젝트 README](../README.md)
- [Datadog 통합 가이드](./DATADOG_INTEGRATION.md)
- [다음 단계 가이드](./NEXT_STEPS_DATADOG.md)

---

**작성일:** 2025-10-27
**최종 수정:** 2025-10-27
