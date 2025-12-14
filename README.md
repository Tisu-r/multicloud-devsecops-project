
# 🚀 MultiCloud DevSecOps Project

GCP Cloud Run Jobs, GitHub Actions, Terraform을 활용한 자동화된 데이터 파이프라인 및 DevSecOps 프로젝트입니다.

## 📋 프로젝트 개요

이 프로젝트는 다음과 같은 자동화된 데이터 파이프라인을 구현합니다:
1. **로그 생성** → 2. **컨테이너화** → 3. **스케줄링 실행** → 4. **모니터링** → 5. **분석**

향후 Datadog, Snowflake 연동을 통한 실시간 로그 분석 및 멀티클라우드 확장을 목표로 합니다.

## 🏗️ 아키텍처

```
┌─────────────────┐    ┌─────────────────┐    ┌──────────────────────────┐
│   GitHub Repo   │───▶│  GitHub Actions │───▶│    Google Cloud          │
│                 │    │  (WIF Auth)     │    │                          │
│ • Source Code   │    │ • Build & Test  │    │ • Artifact Registry      │
│ • Terraform     │    │ • Security Scan │    │ • Cloud Run Jobs         │
│ • Workflows     │    │ • Deploy        │    │ • Cloud Scheduler        │
│                 │    │                 │    │ • Pub/Sub (Topic + Sub)  │
└─────────────────┘    └─────────────────┘    └──────────────────────────┘
                                │                       │
                                │                       ▼
                                │              ┌──────────────────┐
                                ▼              │   GCS Bucket     │
                       ┌─────────────────┐     │ (Terraform State)│
                       │     Datadog     │◀────│ (Build Logs)     │
                       │  (Logs & Alerts)│     └──────────────────┘
                       └─────────────────┘
```

**실행 플로우:**
Cloud Scheduler (2일마다 자정 UTC) → Pub/Sub Topic → Pub/Sub Subscription → Cloud Run Job → Datadog Direct Push

## 📁 프로젝트 구조

```
multicloud-devsecops-project/
├── .github/
│   └── workflows/
│       └── main.yaml              # GitHub Actions CI/CD 파이프라인
├── src/
│   └── log_generator/
│       ├── Dockerfile             # 컨테이너 이미지 설정
│       ├── log_generator.py       # 로그 생성 및 Datadog 전송 스크립트
│       └── requirements.txt       # Python 의존성
├── terraform/
│   └── gcp/
│       ├── backend.tf            # Terraform Backend 설정 (GCS)
│       ├── main.tf               # GCP 리소스 정의
│       ├── provider.tf           # Terraform Provider 설정
│       ├── variables.tf          # 변수 정의
│       └── terraform.tfvars      # 변수 값 설정
├── docs/
│   ├── DATADOG_INTEGRATION.md   # Datadog 통합 가이드
│   ├── DATADOG_MIGRATION_GUIDE.md # Datadog 계정 마이그레이션 가이드
│   └── ...                      # 기타 작업 로그
├── cloudbuild.yaml              # Cloud Build 설정
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
| **WIF Pool** | `projects/1082524335295/locations/global/workloadIdentityPools/github-pool` |
| **WIF Provider** | `projects/1082524335295/locations/global/workloadIdentityPools/github-pool/providers/github-provider` |
| **GitHub Repository** | `lowshot31/lowshot31` |
| **Service Accounts** | `github-action-deployer` (배포), `scheduler-pubsub-publisher` (트리거), `log-generator-job-runner` (실행) |

### GCP 리소스
| 리소스 타입 | 이름 | 설명 |
|------------|------|------|
| **Artifact Registry** | `devsecops-project` | 컨테이너 이미지 저장소 |
| **Cloud Run Job** | `log-generator-job` | 로그 생성 작업 |
| **Cloud Scheduler** | `run-log-generator-job-dev` | 2일마다 자동 실행 (`0 0 */2 * *`) |
| **GCS Bucket** | `main-ember-469911-e9-tfstate` | Terraform State 저장소 |

## 🛠️ 기술 스택

### 클라우드 인프라 (GCP)
- **Artifact Registry**: 컨테이너 이미지 저장소
- **Cloud Run Jobs**: 서버리스 컨테이너 실행
- **Cloud Scheduler**: 스케줄링 자동화
- **Workload Identity Federation**: Key-less 보안 인증

### DevOps & CI/CD
- **GitHub Actions**: 자동화된 빌드, 테스트, 배포 파이프라인
- **Terraform**: Infrastructure as Code (IaC) - GCS Backend
- **Datadog**: 실시간 로그 수집 및 모니터링 (Direct Integration)

### 애플리케이션
- **Python 3.9**: 로그 생성 스크립트
- **Asyncio**: 고성능 비동기 처리
- **Faker Library**: 현실적인 더미 데이터 생성

## ⚙️ 현재 구현 상태

### ✅ 완료된 기능

#### 1. 인프라 및 보안
- Terraform을 통한 GCP 리소스 **IaC(Infrastructure as Code)** 구현
- **Workload Identity Federation (WIF)** 도입으로 Service Account Key 제거
- **GitHub Secrets**를 통한 민감 정보(Datadog API Key 등) 관리
- 최소 권한 원칙(Least Privilege)에 기반한 IAM 역할 구성

#### 2. CI/CD 파이프라인
- GitHub Actions를 통한 **자동 배포 파이프라인** 구축
- 코드 푸시 시 Docker 이미지 빌드 → Artifact Registry 푸시 → Terraform Apply
- Terraform State 관리 자동화 (Cleanup, Init, Import, Apply)

#### 3. 모니터링 (Datadog) ✅
- **Cloud Run Job에서 Datadog으로 로그 직접 전송** 구현
- 환경 변수(`DD_API_KEY`)를 통해 API Key 안전하게 주입
- Access, Business, Security(가상 해킹 시도) 등 다양한 유형의 로그 생성 및 수집
- [Datadog 통합 가이드](docs/DATADOG_INTEGRATION.md) 문서화

#### 4. 비용 최적화 ✅
- 스케줄링 최적화 (10분 → 2일 주기)를 통해 **월 비용 99.7% 절감** 달성
- HTTP 트리거 대신 **Pub/Sub 이벤트 기반 아키텍처**로 전환하여 안정성 확보

### 🚧 진행 예정
1. **Datadog 계정 마이그레이션**: 체험판 종료 대비 정식 계정 전환
2. **보안 스캔 (SecOps)**: CodeQL/Grype을 활용한 컨테이너 및 코드 취약점 자동 점검
3. **Datadog 대시보드 고도화**: 로그 레벨별 시각화 및 이상 탐지 알림 설정
4. **Snowflake 연동**: 장기적인 로그 데이터 웨어하우징 구축

## 🚀 시작하기

### 1. WIF (Workload Identity Federation) 설정

```bash
# 1. WIF Pool 및 Provider 생성
gcloud iam workload-identity-pools create github-pool ...
gcloud iam workload-identity-pools providers create-oidc github-provider ...

# 2. Service Account에 WIF 바인딩 (레포지토리 이름 주의!)
gcloud iam service-accounts add-iam-policy-binding \
  github-action-deployer@main-ember-469911-e9.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/1082524335295/locations/global/workloadIdentityPools/github-pool/attribute.repository/lowshot31/lowshot31"
```

### 2. 환경 변수 설정
`terraform/gcp/terraform.tfvars` 파일을 생성하거나 GitHub Secrets에 다음 변수를 등록해야 합니다.

- `TF_VAR_datadog_api_key`: Datadog API Key

### 3. 배포

```bash
# GitHub Actions를 통해 자동 배포됩니다.
git push origin main
```

## 🔍 트러블슈팅

### WIF 인증 실패 (403 Error)
- GitHub Repository 이름이 WIF Provider의 attribute condition과 일치하는지 확인하십시오. (`lowshot31/lowshot31`)
- Service Account에 `roles/iam.workloadIdentityUser` 권한이 올바르게 부여되었는지 확인하십시오.

### Datadog 로그 미수신
- `DD_API_KEY` 환경 변수가 올바르게 설정되었는지 Cloud Run Job 구성에서 확인하십시오.
- `DD_SITE`가 올바른 리전(예: `us5.datadoghq.com`)을 가리키는지 확인하십시오.

---

**© 2025 MultiCloud DevSecOps Project**
