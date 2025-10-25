# src/log-generator/main.py
import json
import datetime

def generate_simple_log():
    """아주 간단한 테스트용 로그를 생성합니다."""
    log_entry = {
      "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
      "level": "INFO",
      "message": "Log generator is running."
    }
    print(json.dumps(log_entry))

if __name__ == "__main__":
    generate_simple_log()