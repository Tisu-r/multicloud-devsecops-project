
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
│                 │    │                 │    │                  │
│ • Source Code   │    │ • Build & Test  │    │ • Artifact Reg.  │
│ • Terraform     │    │ • Security Scan │    │ • Cloud Run Jobs │
│ • Workflows     │    │ • Deploy        │    │ • Cloud Scheduler│
└─────────────────┘    └─────────────────┘    └──────────────────┘
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
│       ├── main.tf               # GCP 리소스 정의
│       ├── provider.tf           # Terraform Provider 설정
│       └── variables.tf          # 변수 정의
├── cloudbuild.yaml              # Cloud Build 설정
└── README.md                    # 프로젝트 문서
```

## 🛠️ 기술 스택 및 리소스

### **클라우드 인프라 (GCP)**
- **Artifact Registry**: `devsecops-project` - 컨테이너 이미지 저장소
- **Cloud Run Jobs**: `log-generator-job` - 컨테이너화된 로그 생성 작업
- **Cloud Scheduler**: `run-log-generator-job-dev` - 10분마다 자동 실행
- **Cloud Build**: 자동화된 이미지 빌드 및 배포
- **GCS Bucket**: `cloudbuild-logs-main-ember-469911-e9` - 빌드 로그 저장

### **DevOps & CI/CD**
- **GitHub Actions**: 자동화된 빌드, 테스트, 배포 파이프라인
- **Terraform**: Infrastructure as Code (IaC)
- **Docker**: 컨테이너화
- **Cloud Build**: 이미지 빌드 자동화

### **애플리케이션**
- **Python 3.9**: 로그 생성 스크립트
- **Faker Library**: 가짜 데이터 생성
- **Google Cloud Storage SDK**: GCP 연동

### **보안 & 인증**
- **Service Account**: `scheduler-job-invoker` - 스케줄러 전용 계정
- **IAM Roles**: 최소 권한 원칙 적용
- **OIDC 토큰**: 안전한 서비스 간 인증

## ⚙️ 현재 구현 상태

### ✅ 완료된 기능
1. **로그 생성기 개발** 
   - JSON 형식의 랜덤 더미 로그 생성 (access, business, security)
   - Python 스크립트 및 Dockerfile 완성
   
2. **GCP 인프라 구축**
   - Terraform을 통한 Cloud Run Jobs, Cloud Scheduler 설정
   - Service Account 및 IAM 권한 구성
   - 변수화된 설정 (프로젝트 ID, 리전 등)

3. **CI/CD 파이프라인**
   - GitHub Actions 워크플로우 구성
   - Cloud Build를 통한 자동 이미지 빌드
   - Terraform 자동 배포

### 🚧 진행 예정
1. **데이터 포워더 개발**: GCS에서 파일을 읽어 Datadog Logs API로 전송하는 Cloud Function 코드 작성
2. **보안 강화**: CodeQL/Grype 보안 스캔 통합
3. **Datadog 설정**:
   - 수신 로그 파싱 규칙 설정
   - 특정 조건(예: `level:error`)의 로그만 Snowflake로 전달하는 로그 아카이브 구성
4. **Snowflake 설정**: Datadog에서 보내는 데이터를 자동으로 수신하는 Snowpipe 구성

## 🔧 설정 정보

- **GCP 프로젝트 ID**: `main-ember-469911-e9`
- **기본 리전**: `us-central1`
- **Artifact Registry**: `us-central1-docker.pkg.dev/main-ember-469911-e9/devsecops-project`
- **스케줄 주기**: 10분마다 (`*/10 * * * *`)
- **환경**: `dev`

## 🚀 시작하기

### 1. 사전 요구사항
- GCP 계정 및 프로젝트 설정
- Terraform 설치
- GitHub 리포지토리 설정

### 2. 환경 설정
```bash
# GCP 인증
gcloud auth login
gcloud config set project main-ember-469911-e9

# Terraform 초기화
cd terraform/gcp
terraform init
```

### 3. 배포
```bash
# GitHub Actions를 통한 자동 배포 (main 브랜치 푸시 시)
git push origin main

# 수동 Terraform 배포
terraform plan
terraform apply
```

### 4. 모니터링
- GCP Console에서 Cloud Run Jobs 실행 상태 확인
- Cloud Scheduler 작업 모니터링
- Cloud Build 로그 확인

## 📈 향후 발전 방향

### 🔮 단기 목표 (3개월)
- **실시간 이상 탐지**: Datadog Monitors를 활용한 실시간 알림 시스템
- **보안 강화**: 보안 스캔 및 취약점 관리 자동화
- **모니터링 대시보드**: GCP Cloud Monitoring 통합

### 🚀 중기 목표 (6개월)
- **분석 고도화**: Snowflake 연동 및 BI 대시보드(Looker, Tableau) 구축
- **멀티클라우드 확장**: Azure Event Grid, Azure Functions 파이프라인 구축
- **비용 최적화**: 리소스 사용량 기반 자동 스케일링

### 🌟 장기 목표 (1년)
- **ML/AI 통합**: 로그 패턴 분석 및 예측 모델링
- **완전 자동화**: 인프라 프로비저닝부터 모니터링까지 완전 자동화
- **엔터프라이즈 확장**: 대규모 환경 지원 및 고가용성 구성

## 📞 지원 및 기여

- 이슈 리포트: GitHub Issues
- 기능 제안: Pull Requests
- 문서 개선: README 업데이트

---
🤖 **자동화된 DevSecOps 파이프라인으로 더 나은 개발 경험을 제공합니다.**