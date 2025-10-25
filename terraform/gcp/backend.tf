# terraform/gcp/backend.tf

terraform {
  backend "gcs" {
    bucket  = "your-unique-tfstate-bucket-name" # 미리 만들어 둔 GCS 버킷 이름
    prefix  = "terraform/state"
  }
}