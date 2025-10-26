import json
import random
import datetime
import uuid

# pip install Faker
from faker import Faker

fake = Faker()

def generate_log():
    log_type = random.choice(['access', 'business', 'security'])
    
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
        
    elif log_type == 'security':
        # --- 이상치 주입 로직 시작 ---
        # 0.5% (0.005)의 확률로 수상한 로그 생성
        if random.random() < 0.5: 
            # 1. 비정상적인 attempt_count (Isolation Forest의 핵심 피처)
            attempt_count = random.randint(50, 200) 
            # 2. 비정상적인 level (심각도 증가)
            level = "CRITICAL_ANOMALY" 
            # 3. 비정상적인 reason (브루트 포스 시도에 집중)
            reason = "massive_brute_force_attempt"
            
        else:
            # 99.5%는 정상적인 보안 로그 생성
            attempt_count = random.randint(1, 10)
            level = random.choice(["WARN", "ERROR"])
            reason = random.choice(["invalid_credentials", "permission_denied", "unauthorized_access"])
            
        # --- 이상치 주입 로직 끝 ---

        return {
          "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
          "level": level,  # 수정된 level 사용
          "service": "auth-service",
          "event_type": random.choice(["login_failed", "permission_denied", "suspicious_activity"]),
          "message": f"Security event detected: {fake.sentence(nb_words=4)}",
          "details": {
            "user_id": fake.user_name(),
            "source_ip": fake.ipv4(),
            "reason": reason, # 수정된 reason 사용
            "attempt_count": attempt_count # 수정된 attempt_count 사용
          }
        }

if __name__ == "__main__":
    # Cloud Run Job에서 100개의 로그를 생성하여 파일로 저장한다고 가정
    logs = [generate_log() for _ in range(100)]
    
    # 이 데이터를 GCS 버킷에 업로드하는 로직 추가
    # 예: print(json.dumps(logs, indent=2))
    for log in logs:
        print(json.dumps(log))