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
        return {
          "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
          "level": random.choice(["WARN", "ERROR"]),
          "service": "auth-service",
          "event_type": random.choice(["login_failed", "permission_denied", "suspicious_activity"]),
          "message": f"Security event detected: {fake.sentence(nb_words=4)}",
          "details": {
            "user_id": fake.user_name(),
            "source_ip": fake.ipv4(),
            "reason": random.choice(["invalid_credentials", "brute_force_attempt", "unauthorized_access"]),
            "attempt_count": random.randint(1, 10)
          }
        }

if __name__ == "__main__":
    # Cloud Run Job에서 100개의 로그를 생성하여 파일로 저장한다고 가정
    logs = [generate_log() for _ in range(100)]
    
    # 이 데이터를 GCS 버킷에 업로드하는 로직 추가
    # 예: print(json.dumps(logs, indent=2))
    for log in logs:
        print(json.dumps(log))