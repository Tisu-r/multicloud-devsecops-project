# src/log-generator/Dockerfile

# 1. 베이스 이미지 선택
FROM python:3.9-slim

# 2. 작업 디렉토리 설정
WORKDIR /app

# 3. 의존성 파일 복사 및 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. 소스코드 복사
COPY main.py .

# 5. 컨테이너가 시작될 때 실행할 명령어
CMD ["python", "main.py"]