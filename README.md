
# 🚀 MultiCloud DevSecOps Project

GCP Cloud Run Jobs, GitHub Actions, Terraform을 활용한 자동화된 데이터 파이프라인 및 DevSecOps 프로젝트입니다.

## 📋 프로젝트 개요

이 프로젝트는 다음과 같은 자동화된 데이터 파이프라인을 구현합니다:
1. **로그 생성** → 2. **컨테이너화** → 3. **스케줄링 실행** → 4. **모니터링** → 5. **분석**

향후 Datadog, Snowflake 연동을 통한 실시간 로그 분석 및 멀티클라우드 확장을 목표로 합니다.

## 🏗️ 아키텍처

```
┌─────────────────┐    ┌─────────────────┐    ┌──────────────────┐
│   GitHub Repo   │───▶│  GitHub Actions │───▶│  Google Cloud    │
│                 │    │  (WIF Auth)     │    │                  │
│ • Source Code   │    │ • Build & Test  │    │ • Artifact Reg.  │
│ • Terraform     │    │ • Security Scan │    │ • Cloud Run Jobs │
│ • Workflows     │    │ • Deploy        │    │ • Cloud Scheduler│
└─────────────────┘    └─────────────────┘    └──────────────────┘
                                │                       │
                                │                       ▼
                                │              ┌──────────────────┐
                                └─────────────▶│   GCS Bucket     │
                                               │ (Terraform State)│
                                               └──────────────────┘
```

## 📁 프로젝트 구조

```
multicloud-devsecops-project/
├── .github/
│   └── workflows/
│       └── main.yaml              # GitHub Actions CI/CD 파이프라인
├── src/
│   └── log_generator/
│       ├── Dockerfile             # 컨테이너 이미지 설정
│       ├── log_generator.py       # 로그 생성 Python 스크립트
│       └── requirements.txt       # Python 의존성
├── terraform/
│   └── gcp/
│       ├── backend.tf            # Terraform Backend 설정 (GCS)
│       ├── main.tf               # GCP 리소스 정의
│       ├── provider.tf           # Terraform Provider 설정
│       ├── variables.tf          # 변수 정의
│       └── terraform.tfvars      # 변수 값 설정
├── cloudbuild.yaml              # Cloud Build 설정
├── .gitignore                   # Git 제외 파일
└── README.md                    # 프로젝트 문서
```

## 🔧 프로젝트 설정 정보

### GCP 프로젝트
| 항목 | 값 |
|------|-----|
| **프로젝트 ID** | `main-ember-469911-e9` |
| **프로젝트 번호** | `1082524335295` |
| **기본 리전** | `us-central1` |
| **환경** | `dev` |

### 인증 및 보안
| 항목 | 값 |
|------|-----|
| **GitHub Actions SA** | `github-action-deployer@main-ember-469911-e9.iam.gserviceaccount.com` |
| **Scheduler Invoker SA** | `scheduler-job-invoker@main-ember-469911-e9.iam.gserviceaccount.com` |
| **WIF Pool** | `projects/1082524335295/locations/global/workloadIdentityPools/github-pool` |
| **WIF Provider** | `projects/1082524335295/locations/global/workloadIdentityPools/github-pool/providers/github-provider` |
| **GitHub Repository** | `Tisu-r/multicloud-devsecops-project` |

### GCP 리소스
| 리소스 타입 | 이름 | 설명 |
|------------|------|------|
| **Artifact Registry** | `devsecops-project` | 컨테이너 이미지 저장소 |
| **Cloud Run Job** | `log-generator-job` | 로그 생성 작업 |
| **Cloud Scheduler** | `run-log-generator-job-dev` | 10분마다 자동 실행 |
| **GCS Bucket (State)** | `main-ember-469911-e9-tfstate` | Terraform state 관리 |
| **GCS Bucket (Logs)** | `cloudbuild-logs-main-ember-469911-e9` | Cloud Build 로그 |
| **Schedule** | `*/10 * * * *` | 10분마다 실행 |

### 컨테이너 이미지
```
us-central1-docker.pkg.dev/main-ember-469911-e9/devsecops-project/fake_service:${GIT_SHORT_SHA}
```

## 🛠️ 기술 스택

### 클라우드 인프라 (GCP)
- **Artifact Registry**: 컨테이너 이미지 저장소
- **Cloud Run Jobs**: 서버리스 컨테이너 실행
- **Cloud Scheduler**: 스케줄링 자동화
- **Cloud Build**: 이미지 빌드 자동화
- **GCS**: State 파일 및 로그 저장
- **Workload Identity Federation**: 키 없는 안전한 인증

### DevOps & CI/CD
- **GitHub Actions**: 자동화된 빌드, 테스트, 배포 파이프라인
- **Terraform**: Infrastructure as Code (IaC) - GCS Backend
- **Docker**: 컨테이너화
- **Cloud Build**: 이미지 빌드 자동화

### 애플리케이션
- **Python 3.9**: 로그 생성 스크립트
- **Faker Library**: 가짜 데이터 생성
- **Google Cloud Storage SDK**: GCP 연동

## 🔐 IAM 권한 구성

### github-action-deployer 서비스 계정 권한
```yaml
roles:
  - roles/editor                          # 프로젝트 편집 권한
  - roles/storage.admin                   # GCS State 파일 관리
  - roles/run.admin                       # Cloud Run 관리
  - roles/iam.serviceAccountAdmin         # SA 생성/관리
  - roles/iam.serviceAccountUser          # SA 사용
  - roles/iam.serviceAccountTokenCreator  # 토큰 생성
  - roles/iam.workloadIdentityUser        # WIF 인증
  - roles/serviceusage.serviceUsageAdmin  # API 활성화
  - roles/cloudscheduler.admin            # Scheduler 관리
  - roles/artifactregistry.writer         # 이미지 푸시
```

### scheduler-job-invoker 서비스 계정 권한
```yaml
roles:
  - roles/run.invoker  # Cloud Run Job 실행 권한
```

## ⚙️ 현재 구현 상태

### ✅ 완료된 기능

#### 1. 로그 생성기 개발
- JSON 형식의 랜덤 더미 로그 생성 (access, business, security)
- Python 스크립트 및 Dockerfile 완성

#### 2. GCP 인프라 구축
- Terraform을 통한 Cloud Run Jobs, Cloud Scheduler 설정
- Service Account 및 IAM 권한 구성
- **GCS Backend를 통한 Terraform State 관리**
- 변수화된 설정 (프로젝트 ID, 리전 등)

#### 3. CI/CD 파이프라인
- **Workload Identity Federation (WIF) 인증** - 키 없는 안전한 인증
- GitHub Actions 워크플로우 구성
- Cloud Build를 통한 자동 이미지 빌드
- Terraform 자동 배포 (Init, Import, Apply)
- 기존 리소스 자동 import 처리

#### 4. 보안 강화
- Service Account Key 제거 (WIF 사용)
- 최소 권한 원칙 적용
- Terraform State를 GCS에 중앙 관리
- `.gitignore`를 통한 민감 정보 보호

### 🚧 진행 예정
1. **데이터 포워더 개발**: GCS에서 파일을 읽어 Datadog Logs API로 전송하는 Cloud Function 코드 작성
2. **보안 강화**: CodeQL/Grype 보안 스캔 통합
3. **Datadog 설정**:
   - 수신 로그 파싱 규칙 설정
   - 특정 조건(예: `level:error`)의 로그만 Snowflake로 전달하는 로그 아카이브 구성
4. **Snowflake 설정**: Datadog에서 보내는 데이터를 자동으로 수신하는 Snowpipe 구성

## 🚀 시작하기

### 1. 사전 요구사항
- GCP 계정 및 프로젝트 설정
- Terraform 설치
- GitHub 리포지토리 설정
- gcloud CLI 설치

### 2. WIF (Workload Identity Federation) 설정

```bash
# 1. Workload Identity Pool 생성
gcloud iam workload-identity-pools create github-pool \
  --location=global \
  --display-name="GitHub Pool" \
  --project=main-ember-469911-e9

# 2. WIF Provider 생성
gcloud iam workload-identity-pools providers create-oidc github-provider \
  --location=global \
  --workload-identity-pool=github-pool \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub" \
  --attribute-condition="assertion.repository == 'Tisu-r/multicloud-devsecops-project'" \
  --project=main-ember-469911-e9

# 3. Service Account 생성
gcloud iam service-accounts create github-action-deployer \
  --display-name="GitHub Actions Deployer" \
  --project=main-ember-469911-e9

# 4. WIF 바인딩
gcloud iam service-accounts add-iam-policy-binding \
  github-action-deployer@main-ember-469911-e9.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/1082524335295/locations/global/workloadIdentityPools/github-pool/*" \
  --project=main-ember-469911-e9
```

### 3. Terraform State 버킷 생성

```bash
# GCS 버킷 생성
gcloud storage buckets create gs://main-ember-469911-e9-tfstate \
  --project=main-ember-469911-e9 \
  --location=us-central1 \
  --uniform-bucket-level-access

# 버킷 버전 관리 활성화
gcloud storage buckets update gs://main-ember-469911-e9-tfstate \
  --versioning
```

### 4. 환경 설정

```bash
# GCP 인증
gcloud auth login
gcloud config set project main-ember-469911-e9

# Terraform 초기화
cd terraform/gcp
terraform init

# Terraform 변수 파일 확인
cat terraform.tfvars
```

### 5. 배포

```bash
# GitHub Actions를 통한 자동 배포 (main 브랜치 푸시 시)
git push origin main

# 수동 Terraform 배포
cd terraform/gcp
terraform plan
terraform apply
```

### 6. 모니터링

```bash
# Cloud Run Jobs 실행 상태 확인
gcloud run jobs describe log-generator-job \
  --region=us-central1 \
  --project=main-ember-469911-e9

# Cloud Scheduler 확인
gcloud scheduler jobs describe run-log-generator-job-dev \
  --location=us-central1 \
  --project=main-ember-469911-e9

# 최근 실행 로그 확인
gcloud run jobs executions list \
  --job=log-generator-job \
  --region=us-central1 \
  --project=main-ember-469911-e9
```

## 🔍 트러블슈팅

### 403 권한 오류 (Permission Denied)

**증상**: `iam.serviceAccounts.getAccessToken` 권한 거부

**해결**:
```bash
# Service Account에 필요한 권한 부여
gcloud iam service-accounts add-iam-policy-binding \
  github-action-deployer@main-ember-469911-e9.iam.gserviceaccount.com \
  --role="roles/iam.serviceAccountTokenCreator" \
  --member="serviceAccount:github-action-deployer@main-ember-469911-e9.iam.gserviceaccount.com"
```

### Terraform 409 충돌 오류

**증상**: `Resource already exists` 오류

**원인**: Terraform State에 없지만 GCP에 이미 존재하는 리소스

**해결**: GitHub Actions workflow에 import 단계가 자동으로 포함되어 있음 (`.github/workflows/main.yaml:42-57`)

### Terraform Init 멈춤

**증상**: "Do you want to copy existing state" 메시지에서 멈춤

**해결**:
- `.gitignore`에 Terraform state 파일 추가됨
- `terraform init -input=false` 플래그 사용
- Workflow에 cleanup 단계 추가됨

### WIF 인증 실패

**증상**: GitHub Actions에서 GCP 인증 실패

**확인 사항**:
1. WIF Pool과 Provider가 올바르게 설정되었는지 확인
2. GitHub repository 이름이 정확한지 확인
3. Service Account IAM 바인딩 확인

```bash
# WIF 설정 확인
gcloud iam workload-identity-pools providers describe github-provider \
  --workload-identity-pool=github-pool \
  --location=global \
  --project=main-ember-469911-e9

# Service Account IAM 확인
gcloud iam service-accounts get-iam-policy \
  github-action-deployer@main-ember-469911-e9.iam.gserviceaccount.com
```

## 📝 주요 파일 설명

### `.github/workflows/main.yaml`
GitHub Actions CI/CD 파이프라인 정의
- WIF 인증
- Terraform init (state cleanup 포함)
- 기존 리소스 import
- Terraform apply

### `terraform/gcp/backend.tf`
```hcl
terraform {
  backend "gcs" {
    bucket  = "main-ember-469911-e9-tfstate"
    prefix  = "terraform/state"
  }
}
```

### `terraform/gcp/terraform.tfvars`
```hcl
gcp_project_id = "main-ember-469911-e9"
image_url      = "us-docker.pkg.dev/cloudrun/container/hello"  # 기본값
```

## 📈 향후 발전 방향

### 🔮 단기 목표 (3개월)
- **실시간 이상 탐지**: Datadog Monitors를 활용한 실시간 알림 시스템
- **보안 강화**: CodeQL/Grype 보안 스캔 및 취약점 관리 자동화
- **모니터링 대시보드**: GCP Cloud Monitoring 통합
- **환경 분리**: dev, staging, prod 환경 분리

### 🚀 중기 목표 (6개월)
- **분석 고도화**: Snowflake 연동 및 BI 대시보드(Looker, Tableau) 구축
- **멀티클라우드 확장**: Azure Event Grid, Azure Functions 파이프라인 구축
- **비용 최적화**: 리소스 사용량 기반 자동 스케일링
- **DR (Disaster Recovery)**: 백업 및 복구 전략 수립

### 🌟 장기 목표 (1년)
- **ML/AI 통합**: 로그 패턴 분석 및 예측 모델링
- **완전 자동화**: 인프라 프로비저닝부터 모니터링까지 완전 자동화
- **엔터프라이즈 확장**: 대규모 환경 지원 및 고가용성 구성
- **컴플라이언스**: SOC 2, ISO 27001 대응

## 🔄 CI/CD 워크플로우

```
1. 코드 푸시 (main 브랜치)
   ↓
2. GitHub Actions 트리거
   ↓
3. WIF를 통한 GCP 인증
   ↓
4. Terraform State Cleanup
   ↓
5. Terraform Init (-input=false)
   ↓
6. 기존 리소스 Import (continue-on-error)
   ↓
7. 이미지 빌드 대기 (150초)
   ↓
8. Terraform Apply (이미지 URL과 함께)
   ↓
9. Cloud Run Job 업데이트
   ↓
10. Cloud Scheduler 자동 실행 (10분마다)
```

## 📞 지원 및 기여

- **이슈 리포트**: GitHub Issues
- **기능 제안**: Pull Requests
- **문서 개선**: README 업데이트

## 📚 참고 자료

- [Workload Identity Federation 설정 가이드](https://cloud.google.com/iam/docs/workload-identity-federation)
- [Terraform GCS Backend](https://developer.hashicorp.com/terraform/language/settings/backends/gcs)
- [Cloud Run Jobs 문서](https://cloud.google.com/run/docs/create-jobs)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-google-cloud-platform)

---

🤖 **자동화된 DevSecOps 파이프라인으로 더 나은 개발 경험을 제공합니다.**

*Last Updated: 2025-10-26*
