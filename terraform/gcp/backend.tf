# terraform/gcp/backend.tf

terraform {
  backend "gcs" {
    bucket  = "main-ember-469911-e9-tfstate" # GCS 버킷 이름
    prefix  = "terraform/state"
  }
}