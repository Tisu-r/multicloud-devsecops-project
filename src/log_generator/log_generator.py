import json
import random
import datetime
import uuid
# from google.cloud import storage
import os
import requests

# pip install Faker
from faker import Faker

fake = Faker()

# # GCS 버킷 이름: 환경 변수에서 읽어오도록 수정
# BUCKET_NAME = os.environ.get("BUCKET_NAME")
# GCS_FOLDER = "raw_logs"
DD_API_KEY = os.environ.get('DD_API_KEY')
DD_SITE = os.environ.get('DD_SITE', 'us5.datadoghq.com')
def send_to_datadog(log_entry):
    """Datadog Logs API로 로그 전송"""
    if not DD_API_KEY:
        print("WARN: DATADOG_API_KEY environment variable not set. Skipping direct log sending.")
        return 400
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
def generate_log():
    log_type = random.choice(['access', 'business', 'security'])
    
    # --- 1. ACCESS LOG (일반) ---
    if log_type == 'access':
        return {
          "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
          "level": random.choice(["INFO", "INFO", "INFO", "WARN", "ERROR"]),
          "service": random.choice(["api-gateway", "user-service", "product-service"]),
          "event_type": "api_call",
          "message": f"Request to {fake.uri_path()} completed",
          "details": {
            "request_id": str(uuid.uuid4()),
            "http_method": random.choice(["GET", "POST", "PUT", "DELETE"]),
            "path": fake.uri_path(),
            "status_code": random.choices([200, 201, 400, 401, 404, 500, 503], weights=[10, 3, 2, 2, 2, 1, 1])[0],
            "response_time_ms": random.randint(20, 1500),
            "user_id": f"user-{random.randint(1000, 9999)}",
            "source_ip": fake.ipv4()
          }
        }
        
    # --- 2. BUSINESS LOG (일반) ---
    elif log_type == 'business':
        return {
          "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
          "level": "CRITICAL",
          "service": "order-service",
          "event_type": random.choice(["order_processed", "payment_failed"]),
          "message": f"New order #{fake.ean(8)} processed",
          "details": {
            "transaction_id": str(uuid.uuid4()),
            "user_id": f"user-{random.randint(1000, 9999)}",
            "product_ids": [f"prod-{random.randint(1, 100):03d}" for _ in range(random.randint(1, 5))],
            "total_amount": round(random.uniform(10.5, 500.99), 2),
            "currency": random.choice(["USD", "KRW", "EUR"]),
            "payment_method": random.choice(["credit_card", "paypal", "bank_transfer"]),
            "shipping_country": fake.country_code()
          }
        }
        
    # --- 3. SECURITY LOG (ML Anomaly 주입) ---
    elif log_type == 'security':
        # --- ML 이상치 주입 로직 (운영 환경 시뮬레이션: 0.5% 확률) ---
        # 로컬 테스트 후 반드시 0.005로 복구해야 함!
        if random.random() < 0.1: 
            attempt_count = random.randint(50, 200) 
            level = "CRITICAL_ANOMALY" 
            reason = "massive_brute_force_attempt"
            
        else:
            # 99.5%는 정상적인 보안 로그 생성
            attempt_count = random.randint(1, 10)
            level = random.choice(["WARN", "ERROR"])
            reason = random.choice(["invalid_credentials", "permission_denied", "unauthorized_access"])
        # --- 이상치 주입 로직 끝 ---
        
        return {
          "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
          "level": level,
          "service": "auth-service",
          "event_type": random.choice(["login_failed", "permission_denied", "suspicious_activity"]),
          "message": f"Security event detected: {fake.sentence(nb_words=4)}",
          "details": {
            "user_id": fake.user_name(),
            "source_ip": fake.ipv4(),
            "reason": reason,
            "attempt_count": attempt_count
          }
        }

# def upload_to_gcs(data):
#     """생성된 로그 리스트를 GCS에 파일로 업로드합니다."""
#     if not BUCKET_NAME:
#         print("ERROR: BUCKET_NAME environment variable not set. Skipping GCS upload.")
#         return
    
#     timestamp = datetime.datetime.utcnow().strftime("%Y%m%d_%H%M%S")
#     filename = f"{GCS_FOLDER}/log_batch_{timestamp}_{uuid.uuid4()}.jsonl"
    
#     # JSONL 형식으로 변환 (Snowflake의 VARIANT 컬럼이 쉽게 로딩할 수 있는 형식)
#     jsonl_data = "\n".join([json.dumps(log) for log in data])

#     try:
#         client = storage.Client()
#         bucket = client.bucket(BUCKET_NAME)
#         blob = bucket.blob(filename)
        
#         print(f"Uploading {len(data)} logs to gs://{BUCKET_NAME}/{filename}")
#         blob.upload_from_string(jsonl_data, content_type='application/jsonl')
#         print("Upload complete.")
#     except Exception as e:
#         print(f"GCS Upload Error: {e}")


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