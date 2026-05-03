variable "project_name" {
  default = "file-validation"
}

variable "environment" {
  default = "dev"
}

variable "artifact_bucket" {
  description = "S3 bucket where Lambda artifacts are stored"
}

variable "api_key" {
  description = "Demo API key for user endpoints"
  default     = "student-demo-key"
}

variable "admin_api_key" {
  description = "Demo API key for admin endpoints"
  default     = "admin-demo-key"
}

variable "max_file_size_bytes" {
  description = "Maximum file size accepted by the validator Lambda"
  default     = "5242880"
}
