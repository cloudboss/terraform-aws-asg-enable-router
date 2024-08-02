variable "autoscaling_group_name" {
  type = string
}

variable "iam_permissions_boundary" {
  type = string

  default = null
}

variable "memory_size" {
  type = number

  default = 256
}

variable "name" {
  type = string
}

variable "runtime" {
  type = string

  default = "python3.12"
}

variable "tags" {
  type = map(string)

  default = {}
}

variable "vpc_config" {
  type = object({
    id         = string
    subnet_ids = list(string)
  })

  default = null
}
