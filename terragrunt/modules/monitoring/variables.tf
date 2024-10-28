variable "email_sender" {
  description = "Details of the email account from which monitoring alerts are sent"
  type = object({
    address   = string
    transport = string
  })
}

variable "email_sender_auth_username" {
  description = "The username of the email account from which monitoring alerts are sent"
  type        = string
}

variable "email_sender_auth_password" {
  description = "The password of the email account from which monitoring alerts are sent"
  sensitive   = true
  type        = string
}

variable "email_recipient_address" {
  description = "The email address to which monitoring alerts are sent"
  type        = string
}

variable "kube_prometheus_alerts_to_disable" {
  default     = []
  description = "Alerts that kube-prometheus includes, but which we want to disable."
  type        = list(string)
}

variable "kube_prometheus_version" {
  description = "The version of kube-prometheus to use (for PrometheusRules only)"
  type        = string
}

variable "kube_state_metrics_version" {
  description = "The version of kube-state-metrics to use"
  type        = string
}

variable "namespace_name" {
  description = "The name of the namespace to use."
  type        = string
}

variable "prometheus_replicas" {
  description = "The number of Prometheus replicas"
  type        = number
}
