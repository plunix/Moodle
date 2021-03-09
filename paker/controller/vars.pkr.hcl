variable "client_id" {
  type      = string
  sensitive = true
}

variable "client_secret" {
  type      = string
  sensitive = true
}

variable "tenant" {
  type      = string
  sensitive = true
}

variable "phpVer" {
  type    = string
  default = "7.4"
}

variable "moodleVer" {
  type    = string
  default = "MOODLE_39_STABLE"
}