variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "LambdaFunctionName" {
  type    = string
  default = "CFN_TerminationProtection"
}
