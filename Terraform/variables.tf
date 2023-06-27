variable "LambdaFunctionName" {
  type = string
  # type = list
  # type = list(string)
  # type = map
  # type = map(string)
  # type = number
  # type = bool
  default = "CFN_TerminationProtection"
}

variable "Principal_Service" {
  type    = list(any)
  default = ["scheduler", "lambda"]
}
