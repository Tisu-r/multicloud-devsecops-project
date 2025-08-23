# 프로젝트 개요

## 📋 프로젝트 정보
- **프로젝트명**: multicloud-devsecops-project
- **목적**: GCP와 Azure를 위한 자동화된 서버리스 DevSecOps 파이프라인 구현
- **핵심 개념**: Push-to-Deploy 과정에 보안 내재화 및 실시간 모니터링

## 🎯 주요 목표
- **자동화된 배포**: GitHub Actions를 중심으로 한 CI/CD 파이프라인
- **보안 통합**: CodeQL, Grype 등 보안 도구 통합
- **멀티클라우드**: GCP와 Azure 환경 지원
- **실시간 모니터링**: Datadog을 통한 모니터링 및 알림

## 🏗️ 아키텍처 구성요소

### 클라우드 인프라
- **GCP Cloud Run**: 서버리스 컨테이너 실행 환경
- **Azure**: (향후 확장 예정)

### DevSecOps 도구 스택
- **CI/CD**: GitHub Actions
- **IaC**: Terraform
- **컨테이너화**: Docker
- **보안 스캔**: 
  - CodeQL (정적 분석)
  - Grype (취약점 스캔)
- **모니터링**: Datadog

## 📁 프로젝트 구조
```
multicloud-devsecops-project/
├── README.md                 # 프로젝트 설명
├── PROJECT_OVERVIEW.md       # 이 파일
└── terraform/               # Infrastructure as Code
    └── gcp/                # GCP 리소스 정의
        ├── main.tf         # Cloud Run 서비스 및 권한 설정
        ├── provider.tf     # Terraform 프로바이더 설정
        ├── variables.tf    # 변수 정의
        └── terraform.tfvars # 실제 환경값
```

## ⚙️ 현재 구현 상태

### ✅ 완료된 기능
1. **GCP 인프라 설정**
   - Cloud Run API 자동 활성화
   - Cloud Run 서비스 생성 및 배포
   - 공개 액세스 권한 설정 (allUsers)

2. **Terraform 구성**
   - Google Cloud Provider 설정 (v4.50)
   - 변수화된 설정 (프로젝트 ID, 리전, 서비스명)
   - 현재 테스트용 Hello World 컨테이너 이미지 사용

### 🚧 진행 예정
- GitHub Actions 워크플로우 구성
- Docker 빌드 및 푸시 자동화
- 보안 스캔 통합 (CodeQL, Grype)
- Azure 환경 확장
- Datadog 모니터링 설정

## 🔧 설정 정보
- **GCP 프로젝트 ID**: main-ember-469911-e9
- **기본 리전**: us-central1
- **서비스명**: my-devsecops-service
- **현재 컨테이너**: us-docker.pkg.dev/cloudrun/container/hello (테스트용)

## 🚀 시작하기
1. GCP 프로젝트 설정 및 인증
2. Terraform 초기화 및 적용
3. GitHub Actions 워크플로우 설정
4. 보안 정책 및 모니터링 구성

## 📈 향후 발전 방향
- 멀티 환경 지원 (개발/스테이징/프로덕션)
- 고급 보안 정책 적용
- 성능 최적화 및 비용 관리
- 장애 복구 및 백업 전략