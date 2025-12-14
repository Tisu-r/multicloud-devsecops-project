# 이력서 (Draft)

## 📌 프로필 요약
클라우드 인프라 자동화와 백엔드 개발에 강점이 있는 데브옵스 엔지니어입니다. GCP, Terraform, GitHub Actions를 활용한 안전하고 효율적인 CI/CD 파이프라인 구축 경험이 있으며, Python Asyncio를 활용한 고성능 실시간 모니터링 애플리케이션 개발 역량을 보유하고 있습니다. 비용 최적화와 보안(Workload Identity Federation)을 고려한 인프라 설계에 관심이 많습니다.

---

## 🛠 기술 스택
- **Cloud & DevOps**: Google Cloud Platform (Cloud Run, Pub/Sub, Scheduler, GCS), Terraform, GitHub Actions, Docker
- **Backend**: Python, Asyncio, REST API
- **Monitoring & Observability**: Datadog (Logs, Monitors), Cloud Logging
- **Tools**: Git, VS Code

---

## 🚀 프로젝트 경험

### 1. Multi-Cloud DevSecOps Pipeline 구축
**기간**: 2025.10 - 진행 중
**역할**: 1인 개발 (DevOps Engineering)
**Keywords**: `GCP` `Terraform` `GitHub Actions` `Datadog` `WIF`

**주요 내용**:
GCP Cloud Run Jobs와 Pub/Sub을 활용한 이벤트 기반 로그 생성 및 모니터링 파이프라인 구축. Terraform을 이용한 IaC 구현 및 Datadog 연동을 통한 가시성 확보.

**핵심 성과**:
- **인프라 자동화 (IaC)**: Terraform을 사용하여 Cloud Run, Pub/Sub, Scheduler 등 전체 인프라를 코드로 관리하고, GCS Backend를 통해 State를 안전하게 관리.
- **보안 강화 (DevSecOps)**:
    - Service Account Key 없는 인증 방식인 **GCP Workload Identity Federation (WIF)** 도입으로 보안 리스크 제거.
    - GitHub Actions Secrets를 통해 API Key 등 민감 정보 관리.
- **CI/CD 파이프라인 구축**: GitHub Actions와 Cloud Build를 연동하여 코드 푸시 시 Docker 이미지 빌드 및 Terraform 배포가 자동으로 수행되는 파이프라인 구축.
- **모니터링 및 가시성 확보**:
    - Datadog Logs API를 연동하여 애플리케이션 로그를 실시간으로 수집 및 분석.
    - 중요 로그(ERROR, CRITICAL)와 일반 로그를 구분하여 처리하는 로직 구현.
- **비용 최적화**: 스케줄링 전략 개선(10분 → 2일 주기)을 통해 월 클라우드 비용 **99.7% 절감** 달성.
- **아키텍처 개선**: 인증 오류가 발생하는 HTTP 트리거 방식을 Pub/Sub 기반 이벤트 트리거 방식으로 전환하여 **시스템 안정성 확보**.

### 2. Coinbot - 실시간 암호화폐 급등 감지 봇
**기간**: 2025.10 - 진행 중
**역할**: 1인 개발 (Backend Development)
**Keywords**: `Python` `Asyncio` `Telegram Bot API` `Upbit API`

**주요 내용**:
업비트(Upbit)의 전 종목(KRW 마켓)을 실시간으로 감시하여 급등 코인을 탐지하고 텔레그램으로 알림을 발송하는 봇 서비스 개발.

**핵심 성과**:
- **고성능 비동기 처리**: `asyncio`와 `aiohttp` 개념을 적용하여, 단일 스레드에서도 수백 개의 API 요청을 효율적으로 처리하는 로직 구현.
- **API 제한 준수**: 업비트 API의 요청 제한(Throttling)을 준수하기 위해 청크(Chunk) 단위 분할 처리 및 딜레이 로직 구현.
- **사용자 경험(UX) 개선**: `/start`, `/stop`, `/status`, `/set_threshold` 등 다양한 슬래시 커맨드를 통해 사용자가 봇을 쉽게 제어할 수 있도록 개발.
- **안정성 확보**: 네트워크 오류나 API 예외 상황에 대한 견고한 에러 핸들링 로직 추가로 24시간 중단 없는 서비스 구현.
- **테스트 자동화**: `unittest`를 활용하여 핵심 모니터링 로직에 대한 단위 테스트 코드를 작성하고 검증.

---

## 🎓 학력
- (학교명 입력) | (전공 입력) | (입학년월) - (졸업년월)

## 📜 자격증
- (자격증명 입력) | (발행기관) | (취득일)
