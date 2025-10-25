
## ⚙️ 현재 구현 상태

### ✅ 완료된 기능
1. **기본 GCP 인프라 설정 기반 마련**
   - Terraform을 통한 Google Cloud Provider 설정 (v4.50)
   - 변수화된 설정 (프로젝트 ID, 리전 등)

### 🚧 진행 예정
1. **로그 생성기 개발**: JSON 형식의 랜덤 더미 로그를 생성하는 Python 스크립트 및 Dockerfile 작성
2. **데이터 포워더 개발**: GCS에서 파일을 읽어 Datadog Logs API로 전송하는 Cloud Function 코드 작성
3. **Terraform 확장**: Cloud Scheduler, Cloud Run Job, GCS Bucket, Cloud Function 리소스를 Terraform 코드로 정의
4. **GitHub Actions 워크플로우 구성**:
   - `log-generator` 코드 Push 시, CodeQL/Grype 스캔 후 Docker 이미지를 빌드하여 Artifact Registry에 푸시
   - Terraform을 실행하여 변경된 인프라(Job, Function 등)를 GCP에 배포
5. **Datadog 설정**:
   - 수신 로그 파싱 규칙 설정
   - 특정 조건(예: `level:error`)의 로그만 Snowflake로 전달하는 로그 아카이브 또는 파이프라인 구성
6. **Snowflake 설정**: Datadog에서 보내는 데이터를 자동으로 수신하는 Snowpipe 구성

## 🔧 설정 정보
- **GCP 프로젝트 ID**: main-ember-469911-e9
- **기본 리전**: us-central1
- **기본 리소스 접두사**: my-data-pipeline

## 🚀 시작하기
1. GCP 프로젝트 설정 및 인증
2. `src` 디렉토리 내 로그 생성기 및 포워더 코드 초기 개발
3. Terraform을 사용하여 전체 인프라 정의 및 배포
4. GitHub Actions 워크플로우 설정 및 시크릿(Datadog API Key 등) 구성
5. Datadog 및 Snowflake 파이프라인 연동 설정

## 📈 향후 발전 방향
- **실시간 이상 탐지**: Datadog Monitors를 활용하여 특정 패턴의 로그가 감지되면 실시간 알림 생성
- **분석 고도화**: Snowflake에 적재된 데이터를 활용한 BI 대시보드(Looker, Tableau) 연동
- **멀티클라우드 확장**: Azure Event Grid, Azure Functions, Azure Blob Storage를 이용한 동일한 데이터 파이프라인 구축
- **비용 최적화**: 데이터 처리량에 따른 Cloud Run/Function의 리소스 할당 최적화