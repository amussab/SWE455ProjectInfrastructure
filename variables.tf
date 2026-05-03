variable "project_name" {
  default = "file-validation"
}

variable "environment" {
  default = "dev"
}

variable "artifact_bucket" {
  description = "S3 bucket where Lambda artifacts are stored"
}