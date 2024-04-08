variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1" 
}

variable "bucket_name" {
  description = "Bucket Name"
  type        = string
  default     = "front-56-backend" 
}

variable "api_gateway_name" {
  description = "Api gateway_name"
  type        = string
  default     = "backendAppApiGateway" 
}

variable "stage_name" {
  description = "Deployment stage"
  type        = string
  default     = "final" 
}
